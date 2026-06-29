/*
    Copyright (C) 2020 $uicidE.
    Permission is granted to copy, distribute and/or modify this document
    under the terms of the GNU Free Documentation License, Version 1.3
    or any later version published by the Free Software Foundation;
    with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
    A copy of the license is included in the section entitled "GNU
    Free Documentation License".
*/

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "KilleR_gamea"
#define PLUGIN_VERSION "1.0"
#define PREFIX "[AdminList]"

bool g_bVisible[MAXPLAYERS + 1] = true;

#include <sourcemod>

public Plugin myinfo = {
	name = "[ANY] Admin List",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "http://suicidee.cf/"
};

public void OnPluginStart(){
	RegConsoleCmd("sm_admins", Cmd_Admins);
}

public void OnClientPostAdminCheck(int client){
	if (IsFakeClient(client)){
		return;
	}
	
	g_bVisible[client] = true;
}

public void OnClientDisconnect(int client){
	if (IsFakeClient(client)){
		return;
	}
	
	g_bVisible[client] = false;
}

public Action Cmd_Admins(int client, int args){
	if (IsValidClient(client)){
		Menu_Main(client);
	}
	return Plugin_Handled;
}

void Menu_Main(int client){
	Menu menu = new Menu(MenuCallBack_Main, MENU_ACTIONS_ALL);
	menu.SetTitle("%s Online \nMain Menu", PREFIX);
	
	menu.AddItem("admins", "Online Admins");
	menu.AddItem("vip", "Online VIP");
	
	if (IsValidAdmin(client)){
		menu.AddItem("adminsettings", "Admin Settings");
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuCallBack_Main(Menu menu, MenuAction mAction, int param1, int param2){
	if (mAction == MenuAction_Select){
		char szItem[32];
		menu.GetItem(param2, szItem, sizeof(szItem));
		
		if (StrEqual(szItem, "admins")){
			Menu_Admins(param1);
			
		} else if (StrEqual(szItem, "vip")){
			Menu_VIP(param1);
			
		} else if (StrEqual(szItem, "adminsettings")){
			Menu_Settings(param1);
		}
		
	} else if (mAction == MenuAction_End){
		delete menu;
	}
}

void Menu_Admins(int client){
	Menu menu = new Menu(MenuCallBack_Admins, MENU_ACTIONS_ALL);
	menu.SetTitle("%s Online \nAdmins", PREFIX);
	
	char szName[MAX_NAME_LENGTH];
	
	if (GetAdminsOnlineCount() == 0){
		menu.AddItem("", "There are no currently online admins.");
	}
	
	for (int i = 1; i <= MaxClients; i++){
		if (IsValidClient(i) && IsValidAdmin(i) && g_bVisible[i]){
			Format(szName, sizeof(szName), "%N", i);
			menu.AddItem("", szName);
		}
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuCallBack_Admins(Menu menu, MenuAction mAction, int param1, int param2){
	if (mAction == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		Menu_Main(param1);
		
	} else if (mAction == MenuAction_Select){
		Menu_Admins(param1);
		
	} else if (mAction == MenuAction_End){
		delete menu;
	}
}

void Menu_VIP(int client){
	Menu menu = new Menu(MenuCallBack_VIP, MENU_ACTIONS_ALL);
	menu.SetTitle("%s Online \nVIP", PREFIX);
	
	char szName[MAX_NAME_LENGTH];
	
	if (GetVIPOnlineCount() == 0){
		menu.AddItem("", "There are no currently online VIPs.");
	}
	
	for (int i = 1; i <= MaxClients; i++){
		if (IsValidClient(i) && IsVIPClient(i)){
			Format(szName, sizeof(szName), "%N", i);
			menu.AddItem("", szName);
		}
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuCallBack_VIP(Menu menu, MenuAction mAction, int param1, int param2){
	if (mAction == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		Menu_Main(param1);
		
	} else if (mAction == MenuAction_Select){
		Menu_VIP(param1);
		
	} else if (mAction == MenuAction_End){
		delete menu;
	}
}

void Menu_Settings(int client){
	if (!IsValidAdmin(client)){
		PrintToChat(client, " \x10%s\x01 You do not have access to this command.", PREFIX);
		return;
	}
	
	char szBuffer[512];
	
	Menu menu = new Menu(MenuCallBack_Settings, MENU_ACTIONS_ALL);
	menu.SetTitle("%s Online \nAdmin Settings", PREFIX);
	
	Format(szBuffer, sizeof(szBuffer), "[%s] Visible on admin list", g_bVisible[client] ? "Yes":"No");
	menu.AddItem("invisible", szBuffer);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuCallBack_Settings(Menu menu, MenuAction mAction, int param1, int param2){
	if (mAction == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		Menu_Main(param1);
		
	} else if (mAction == MenuAction_Select){
		char szItem[32];
		menu.GetItem(param2, szItem, sizeof(szItem));
		
		if (StrEqual(szItem, "invisible")){
			g_bVisible[param1] = !g_bVisible[param1];
			PrintToChat(param1, " \x10%s\x01 You are now %s\x01 on the \x07admin\x01 list.", PREFIX, g_bVisible[param1] ? "\x04visible":"\x07invisible");
		}
		
		Menu_Settings(param1);
		
	} else if (mAction == MenuAction_End){
		delete menu;
	}
}

stock int GetAdminsOnlineCount(){
	int iCounter = 0;
	
	for (int i = 1; i <= MaxClients; i++){
		if (IsValidClient(i) && IsValidAdmin(i) && g_bVisible[i]){
			iCounter++;
		}
	}
	return iCounter;
}

stock int GetVIPOnlineCount(){
	int iCounter = 0;
	
	for (int i = 1; i <= MaxClients; i++){
		if (IsValidClient(i) && IsVIPClient(i)){
			iCounter++;
		}
	}
	return iCounter;
}

stock bool IsVIPClient(int client){
	if (client >= 1 && client <= MaxClients && CheckCommandAccess(client, "", ADMFLAG_CUSTOM1)){
		return true;
	}
	return false;
}

stock bool IsValidAdmin(int client){
	if (client >= 1 && client <= MaxClients && CheckCommandAccess(client, "", ADMFLAG_SLAY)){
		return true;
	}
	return false;
}

stock bool IsValidClient(int client){
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client) && !IsClientReplay(client)){
		return true;
	}
	return false;
}