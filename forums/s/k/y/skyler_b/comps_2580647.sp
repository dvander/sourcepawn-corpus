#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "skyler"
#define PLUGIN_VERSION "2.72"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <skyler>
#include <smlib>

EngineVersion g_Game;

int ctamount = 0;
int tamount = 0;
bool kniferound, kniferoundend, compstop;
public Plugin myinfo = 
{
	name = "comps", 
	author = PLUGIN_AUTHOR, 
	description = "Rom zona", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/member.php?u=283190"
};

public OnPluginStart()
{
	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO && g_Game != Engine_CSS)
		SetFailState("This plugin is for CSGO/CSS only.");
	RegAdminCmd("sm_comp", CMD_comp, ADMFLAG_BAN, "");
	HookEvent("round_end", Event_RoundEnd);
}
public Action CMD_comp(int client, args)
{
	comp(client);
}
public void comp(int client)
{
	Menu maincomp = new Menu(MainCompHander);
	maincomp.SetTitle("Main competitive menu - 5vs5");
	if (GetPlayerAmountTeamCT() == 5 && GetPlayerAmountTeamT() == 5)
	{
		maincomp.AddItem("cont", "continue comp", ITEMDRAW_DISABLED);
		maincomp.AddItem("stop", "stop comp", ITEMDRAW_DISABLED);
		maincomp.AddItem("knife", "start knife round");
		maincomp.AddItem("sknife", "stop knife round", ITEMDRAW_DISABLED);
		maincomp.AddItem("swap", "swap teams", ITEMDRAW_DISABLED);
		maincomp.AddItem("stay", "stay teams", ITEMDRAW_DISABLED);
	}
	else if (GetPlayerAmountTeamCT() <= 5 && GetPlayerAmountTeamT() <= 5)
	{
		maincomp.AddItem("cont", "continue comp", ITEMDRAW_DISABLED);
		maincomp.AddItem("stop", "stop comp", ITEMDRAW_DISABLED);
		maincomp.AddItem("knife", "start knife round", ITEMDRAW_DISABLED);
		maincomp.AddItem("sknife", "stop knife round", ITEMDRAW_DISABLED);
		maincomp.AddItem("swap", "swap teams", ITEMDRAW_DISABLED);
		maincomp.AddItem("stay", "stay teams", ITEMDRAW_DISABLED);
	}
	else if (kniferound && GetPlayerAmountTeamCT() <= 5 && GetPlayerAmountTeamT() <= 5)
	{
		maincomp.AddItem("cont", "continue comp", ITEMDRAW_DISABLED);
		maincomp.AddItem("stop", "stop comp", ITEMDRAW_DISABLED);
		maincomp.AddItem("knife", "start knife round", ITEMDRAW_DISABLED);
		maincomp.AddItem("sknife", "stop knife round");
		maincomp.AddItem("swap", "swap teams", ITEMDRAW_DISABLED);
		maincomp.AddItem("stay", "stay teams", ITEMDRAW_DISABLED);
	}
	else if (!compstop && !kniferound && kniferoundend && GetPlayerAmountTeamCT() <= 5 && GetPlayerAmountTeamT() <= 5)
	{
		maincomp.AddItem("cont", "continue comp", ITEMDRAW_DISABLED);
		maincomp.AddItem("stop", "stop comp");
		maincomp.AddItem("knife", "start knife round", ITEMDRAW_DISABLED);
		maincomp.AddItem("sknife", "stop knife round", ITEMDRAW_DISABLED);
		maincomp.AddItem("swap", "swap teams");
		maincomp.AddItem("stay", "currect teams");
	}
	else if (compstop && !kniferound && kniferoundend && GetPlayerAmountTeamCT() <= 5 && GetPlayerAmountTeamT() <= 5)
	{
		maincomp.AddItem("cont", "continue comp");
		maincomp.AddItem("stop", "stop comp", ITEMDRAW_DISABLED);
		maincomp.AddItem("knife", "start knife round", ITEMDRAW_DISABLED);
		maincomp.AddItem("sknife", "stop knife round", ITEMDRAW_DISABLED);
		maincomp.AddItem("swap", "swap teams");
		maincomp.AddItem("stay", "currect teams");
	}
	maincomp.ExitButton = true;
	maincomp.Display(client, MENU_TIME_FOREVER);
}
public int MainCompHander(Menu maincomp, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		maincomp.GetItem(item, info, sizeof(info));
		if (StrEqual(info, "cont"))
		{
			PrintToChatAll("[SM] the comp continues");
			for (int i = 0; i <= MaxClients; i++)
				SetEntityMoveType(i, MOVETYPE_WALK);
			compstop = !compstop;
			maincomp.Display(client, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(info, "stop"))
		{
			PrintToChatAll("[SM] the comp stop");
			for (int i = 0; i <= MaxClients; i++)
				SetEntityMoveType(i, MOVETYPE_NONE);
			compstop = !compstop;
			maincomp.Display(client, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(info, "knife"))
		{
			kniferound = !kniferound;
			if (kniferound)
			{
				ServerCommand("bot_kick");
				ServerCommand("mp_restartgame 3");
				ServerCommand("mp_warmup_end");
				PrintToChatAll("[SM] Knife round start!");
				for (int i = 0; i <= MaxClients; i++)
				{
					RemoveAllWeapons(i);
					GivePlayerItem(i, "weapon_knife");
				}
				ServerCommand("mp_buytime 0");
			}
			maincomp.Display(client, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(info, "sknife"))
		{
			kniferound = !kniferound;
			kniferoundend = !kniferoundend;
			ServerCommand("mp_buytime 45");
		}
		
		if (StrEqual(info, "swap"))
		{
			PrintToChatAll("[SM] teams is swaping, the comp begin!");
			//i know!. i am lazy using servercommand function...
			ServerCommand("sm_swap @all");
			ServerCommand("mp_restartgame 1");
			maincomp.Display(client, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(info, "stay"))
		{
			PrintToChatAll("[SM] teams stay the comp begin!");
			ServerCommand("mp_restartgame 1");
			maincomp.Display(client, MENU_TIME_FOREVER);
		}
	}
}
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (kniferound)
	{
		ctamount = GetAlivePlayerAmountTeamCT();
		tamount = GetAlivePlayerAmountTeamT();
		if (ctamount == 0)
		{
			PrintToChatAll("[SM] The terrorist wins! the ability to make the choose granted!");
		}
		if (tamount == 0)
		{
			PrintToChatAll("[SM] The counter terrorist wins! the ability to make the choose granted!");
		}
		kniferoundend = !kniferoundend;
	}
}