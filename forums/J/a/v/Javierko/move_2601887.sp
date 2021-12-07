#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Javierko"
#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[CS:GO] Move",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "https://hexmania.eu"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_move", Command_Move, ADMFLAG_SLAY);
}

public Action Command_Move(int client, int args)
{
	Menu menu = new Menu(m_menu);
	menu.SetTitle("Move player:");
	menu.AddItem("zctt", "From CT to T");
	menu.AddItem("ztct", "From T to CT");
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int m_menu(Menu menu, MenuAction action, int client, int index)
{
	if(action == MenuAction_Select)
	{
		char szItem[12];
		menu.GetItem(index, szItem, sizeof(szItem));
		if(StrEqual(szItem, "zctt"))
		{
			CTdoT(client);
		}
		else if(StrEqual(szItem, "ztct"))
		{
			TdoCT(client);
		}
	}
}

public void CTdoT(int client)
{
	Menu menu = new Menu(m_ctdot);
	menu.SetTitle("Move player to Terrorist team");
	
	for (int i = 1; i < MAXPLAYERS; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			char Id[128];
			IntToString(i, Id, sizeof(Id));
			
			char targetName[MAX_NAME_LENGTH + 1];
			GetClientName(i, targetName, sizeof(targetName));
			
			menu.AddItem(Id, targetName);
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int m_ctdot(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select) 
	{		
		char info[64];
		menu.GetItem(item, info, sizeof(info));
		
		int target = StringToInt(info);
		ChangeClientTeam(target, CS_TEAM_T);
		ForcePlayerSuicide(target);
		PrintToChatAll(" [\x02Move\x01] Player %N has been moved to Terrorists.", target);
	}
	else if (action == MenuAction_End) 
	{
		delete menu;
	}
}

public void TdoCT(int client)
{
	Menu menu = new Menu(m_tdoct);
	menu.SetTitle("Move player to Counter-Terrorists team");
	
	for (int i = 1; i < MAXPLAYERS; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			char Id[128];
			IntToString(i, Id, sizeof(Id));
			
			char targetName[MAX_NAME_LENGTH + 1];
			GetClientName(i, targetName, sizeof(targetName));
			
			menu.AddItem(Id, targetName);
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int m_tdoct(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select) 
	{		
		char info[64];
		menu.GetItem(item, info, sizeof(info));
		
		int target = StringToInt(info);
		ChangeClientTeam(target, CS_TEAM_CT);
		ForcePlayerSuicide(target);
		PrintToChatAll(" [\x02Move\x01] Player %N has been moved to Counter-Terrorists", target);
	}
	else if (action == MenuAction_End) 
	{
		delete menu;
	}
}
