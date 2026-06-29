#include <sourcemod>
#include <adminmenu>

#pragma newdecls required

public Plugin myinfo = {
	name = "Steam Profile",
	author = "Facksy",
	description = "Steam Profile",
	version = "1.0.1",
	url = "http://steamcommunity.com/id/iamfacksy/"
};

public void OnPluginStart(){
	CreateConVar("sm_team_profile_version", "1.0.1", "Steam Profile version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_id", Cmd_id, "id");
	RegConsoleCmd("sm_steamid", Cmd_id, "id");
	RegConsoleCmd("sm_info", Cmd_id, "id");
	
	LoadTranslations("common.phrases");
}

public Action Cmd_id(int client, int args){
	if(!args)
		ShowTheMenu(client);
	else{
		char arg1[64];
		GetCmdArg(1, arg1, 64);
		int target = FindTarget(client, arg1);
		if(target != -1)
			DoTheMenu(client, target);
	}
}

void ShowTheMenu(int client){
	Menu menu = new Menu(MenuName);
	menu.SetTitle("Choose a player");
	AddTargetsToMenu(menu, 0);
	menu.Display(client, 0);
}
	
int MenuName(Menu menu, MenuAction action, int client, int param2){
	switch(action){
		case MenuAction_End: delete menu;
		case MenuAction_Select:{
			int target;
			char info[12];
			menu.GetItem(param2, info, 12);
			target = GetClientOfUserId(StringToInt(info));
			if(target)
				DoTheMenu(client, target);
			else
				PrintToChat(client, "No more Valid");
		}
	}
}

void DoTheMenu(int client, int target){
	char strvar[64], strvar2[64];
	
	Menu menu = new Menu(SteamID);
	menu.SetTitle("Info about %N", target);
	GetClientAuthId(target, AuthId_Steam2, strvar, 64);
	Format(strvar, 64, "SteamID: %s", strvar);
	menu.AddItem("", strvar, 1);
	GetClientAuthId(target, AuthId_SteamID64, strvar2, 64);
	Format(strvar, 64, "SteamID64: %s", strvar2);
	menu.AddItem("", strvar, 1);
	
	if(GetUserFlagBits(target) & (ADMFLAG_ROOT))
		menu.AddItem("", "Status: Server Owner", 1);
	else if(GetUserFlagBits(target) & (ADMFLAG_SLAY))
		menu.AddItem("", "Status: Server Admin", 1);
	else
		menu.AddItem("", "Status: Regular player", 1);	    
	
	Format(strvar2, 64, "http://steamcommunity.com/profiles/%s", strvar2);
	if(!IsFakeClient(target))
		menu.AddItem(strvar2, "View his steam profile");
	else
		menu.AddItem("", "Bot...", 1);
	menu.Display(client, 0);
}

int SteamID(Menu menu, MenuAction action, int client, int param2){
    switch(action){
		case MenuAction_End: delete menu;
		case MenuAction_Select:{
			char xinfo[64];
			menu.GetItem(param2, xinfo, 64);
			KeyValues kv = CreateKeyValues("data");
			kv.SetString("title", "Steam Profile");
			kv.SetString("msg", xinfo);
			kv.SetNum("customsvr", 1);
			kv.SetNum("type", MOTDPANEL_TYPE_URL);
			ShowVGUIPanel(client, "info", kv, true);
			delete kv;
		}
	}
}