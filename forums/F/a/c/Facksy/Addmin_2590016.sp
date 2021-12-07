#include <sourcemod>

#pragma newdecls required

#define ADDMIN_VERSION	"1.0.1" //Don't change
#define PREFIX	"\x07ADFF2F[Addmin]\x01"
#define GREENYELLOW	"\x07ADFF2F"

#define FLAG_REQUIRED   ADMFLAG_ROOT

public Plugin myinfo = 
{
	name = "In Game Admin Manager",
	author = "Facksy",
	description = "Manage players in game, to change their group and their flags",
	version = ADDMIN_VERSION,
	url = "http://steamcommunity.com/id/iamfacksy/"
};

char regSteamid[MAXPLAYERS+1][64], regName[MAXPLAYERS+1][64], regGroup[MAXPLAYERS+1][64], regFlags[MAXPLAYERS+1][64];
int biState[MAXPLAYERS+1];

public void OnPluginStart(){
	CreateConVar("sm_addmin_version", ADDMIN_VERSION, "Addmin version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	RegAdminCmd("sm_addmin", Cmd_Addmin, FLAG_REQUIRED, "Open Admin Manager");
	RegAdminCmd("sm_addmins", Cmd_Addmin, FLAG_REQUIRED, "Open Admin Manager");
	RegAdminCmd("sm_addadmin", Cmd_Addmin, FLAG_REQUIRED, "Open Admin Manager");
	RegAdminCmd("sm_addadmins", Cmd_Addmin, FLAG_REQUIRED, "Open Admin Manager");
	RegAdminCmd("sm_adminmanager", Cmd_Addmin, FLAG_REQUIRED, "Open Admin Manager");
	CheckAdminFile();
}

void CheckAdminFile(){
	File hFile = OpenFile("addons/sourcemod/configs/admins.cfg", "r");
	char strvar[128];
	hFile.ReadLine(strvar, 128)
	delete hFile;
	TrimString(strvar);
	if(!StrEqual(strvar, "\"Admins\"", false) && !StrEqual(strvar, "Admins", false))
		SetFailState("Remove comments in admin.cfg, the first line needs to be \"Admins\"");
}

public void OnMapStart(){
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			InitialiseCl(i);
}

void InitialiseCl(int client){
	if(IsValidClient(client)){
		regSteamid[client][0] = 0;
		regGroup[client][0] = 0;
		regFlags[client][0] = 0;
		biState[client] = 0;
	}
}

public Action Cmd_Addmin(int client, int args){
	if(client){
		InitialiseCl(client);
		Menu menu = new Menu(MenuHandler_Menu);
		menu.SetTitle("-=- In-Game Admin Manager -=-");
		menu.AddItem("", "-----", 1);
		menu.AddItem("", "View in-game players");
		menu.AddItem("", "Add/Modify Player with SteamID");
		menu.AddItem("", "View file admin.cfg");
		menu.Display(client, 0);
	}
	else
		PrintToServer("[SM] Command can only be used in game");
	return Plugin_Handled;
}

int MenuHandler_Menu(Menu menu, MenuAction action, int client, int param2){
	switch(action){
		case MenuAction_End: delete menu;
		case MenuAction_Select:{
			switch(param2){
				case 1: InGamePlayersMenu(client);
				case 2: {
					PrintToChat(client, "%s Enter a steamid (STEAM_0:)...", PREFIX);
					biState[client] = 1;
				}
				case 3: AdminFileMenu(client);
			}
		}
	}
}

void InGamePlayersMenu(int client){
	Menu menu = new Menu(MenuHandler_AllPlayers);
	menu.SetTitle("List of all Online Players");
	for(int i = 1; i <= MaxClients; i++){
		if(IsClientInGame(i)){
			char sName[64], sUID[64];
			GetClientName(i, sName, 64);
			IntToString(GetClientUserId(i), sUID, 64);
			menu.AddItem(sUID, sName, IsFakeClient(i) ? 1 : 0);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

int MenuHandler_AllPlayers(Menu menu, MenuAction action, int client, int param2){
	switch (action){
		case MenuAction_End: delete menu;
		case MenuAction_Cancel: if(param2 == -6) Cmd_Addmin(client, 0);
		case MenuAction_Select:{
			char sInfo[64];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			int target = GetClientOfUserId(StringToInt(sInfo));
			if(IsValidClient(target)){
				GetClientAuthId(target, AuthId_Steam2, regSteamid[client], 64);
				GetClientName(target, regName[client], 64);
				if(!SearchInCfg(client))
					GetClientName(target, regName[client], 64);
				ShowPlayer(client);
			}
		}
	}
}

bool SearchInCfg(int client){
	char strvar[64];
	KeyValues KvAdmins = CreateKeyValues("Admins");
	KvAdmins.ImportFromFile("addons/sourcemod/configs/admins.cfg");
	KvAdmins.GotoFirstSubKey();
	do{
		KvAdmins.GetString("identity", strvar, 64);
		if(StrEqual(regSteamid[client], strvar)){
			KvAdmins.GetSectionName(regName[client], 64);
			KvAdmins.GetString("group", regGroup[client], 64);
			KvAdmins.GetString("flags", regFlags[client], 64);
			return true;
		}
		strvar[0] = 0;
	}
	while(KvAdmins.GotoNextKey());
	return false;
}

void ShowPlayer(int client){
	biState[client] = 0;
	char strvar[64];
	Menu menu = new Menu(MenuHandler_ShowPlayer);
	menu.SetTitle("Info about this admin: %s\n --------------", regName[client]);
	// menu.AddItem("", "------", ITEMDRAW_DISABLED);
	Format(strvar, 64, "His SteamID: %s", regSteamid[client][0]);
	menu.AddItem("", strvar, ITEMDRAW_DISABLED);
	Format(strvar, 64, "His group: %s", regGroup[client][0] ? regGroup[client] : "ø");
	menu.AddItem("", strvar, ITEMDRAW_DISABLED);
	Format(strvar, 64, "His%s flags: %s", regGroup[client][0] ? " additional" : "", regFlags[client][0] ? regFlags[client] : "ø");
	menu.AddItem("", strvar, ITEMDRAW_DISABLED);
	menu.AddItem("", "Change his admin name");
	menu.AddItem("", "Set his group");
	menu.AddItem("", "Modify his flags");
	menu.Display(client, 0);
}

int MenuHandler_ShowPlayer(Menu menu, MenuAction action, int client, int param2){
	switch (action){
		case MenuAction_End: delete menu;
		case MenuAction_Cancel: if(param2 == -6) InGamePlayersMenu(client);
		case MenuAction_Select: {
			if(param2 == 3){
				biState[client] = 3;
				PrintToChat(client, "%s Set a new admin name.", PREFIX);
			}
			if(param2 == 4)
				ChooseGroupMenu(client);
			if(param2 == 5)
				ChooseFlagMenu(client, 0);
		}
	}
}

void ChooseGroupMenu(int client){
	if(FileExists("addons/sourcemod/configs/admin_groups.cfg")){
		char strvar[64];
		Menu menu = new Menu(MenuHandler_Group);
		menu.SetTitle("Group of %s", regName[client]);
		menu.AddItem("", "-None-");
		KeyValues KvGroups = new KeyValues("Groups");
		KvGroups.ImportFromFile("addons/sourcemod/configs/admin_groups.cfg");
		if(KvGroups.GotoFirstSubKey()){
			do{
				KvGroups.GetSectionName(strvar, 64);
				menu.AddItem(strvar, strvar);
			}while(KvGroups.GotoNextKey());
			menu.ExitBackButton = true;
			menu.Display(client, 0);
		}
		else{
			PrintToChat(client, "%s Cfg file is empty.", PREFIX)
			ShowPlayer(client);
		}
	}
	else{
		PrintToChat(client, "%s Cfg file doesnt exists.", PREFIX)
		ShowPlayer(client);
	}
}

int MenuHandler_Group(Menu menu, MenuAction action, int client, int param2){
	switch(action){
		case MenuAction_End: delete menu;
		case MenuAction_Cancel: if(param2 == -6) ShowPlayer(client);
		case MenuAction_Select:{
			menu.GetItem(param2, regGroup[client], 64);
			PrintToChat(client, "%s Succesfully changed %s's group to %s\"%s\".", PREFIX, regName[client], GREENYELLOW, regGroup[client]);
			UpdateAdmin(client);
		}
	}
}

void ChooseFlagMenu(int client, int iPage){
	char strvar[64];
	Menu menu = new Menu(MenuHandler_Flags);
	menu.SetTitle("%s of %s", regGroup[client][0] ? "Additionals flags" : "Flags", regName[client]);
	Format(strvar, 64, "[%s]Flag a: Reserved slots", (CheckFlags(client, "a") ? "x" : ""));
	menu.AddItem("a", strvar);
	Format(strvar, 64, "[%s]Flag b: Generic admin, required for admins", (CheckFlags(client, "b") ? "x" : ""));
	menu.AddItem("b", strvar);
	Format(strvar, 64, "[%s]Flag c: Kick other players", (CheckFlags(client, "c") ? "x" : ""));
	menu.AddItem("c", strvar);
	Format(strvar, 64, "[%s]Flag d: Banning other players", (CheckFlags(client, "d") ? "x" : ""));
	menu.AddItem("d", strvar);
	Format(strvar, 64, "[%s]Flag e: Removing bans", (CheckFlags(client, "e") ? "x" : ""));
	menu.AddItem("e", strvar);
	Format(strvar, 64, "[%s]Flag f: Slaying other players", (CheckFlags(client, "f") ? "x" : ""));
	menu.AddItem("f", strvar);
	Format(strvar, 64, "[%s]Flag g: Changing the map", (CheckFlags(client, "g") ? "x" : ""));
	menu.AddItem("g", strvar);
	Format(strvar, 64, "[%s]Flag h: Changing cvars", (CheckFlags(client, "h") ? "x" : ""));
	menu.AddItem("h", strvar);
	Format(strvar, 64, "[%s]Flag i: Changing configs", (CheckFlags(client, "i") ? "x" : ""));
	menu.AddItem("i", strvar);
	Format(strvar, 64, "[%s]Flag j: Special chat privileges", (CheckFlags(client, "j") ? "x" : ""));
	menu.AddItem("j", strvar);
	Format(strvar, 64, "[%s]Flag k: Voting", (CheckFlags(client, "k") ? "x" : ""));
	menu.AddItem("k", strvar);
	Format(strvar, 64, "[%s]Flag l: Password the server", (CheckFlags(client, "l") ? "x" : ""));
	menu.AddItem("l", strvar);
	Format(strvar, 64, "[%s]Flag m: Remote console", (CheckFlags(client, "m") ? "x" : ""));
	menu.AddItem("m", strvar);
	Format(strvar, 64, "[%s]Flag n: Change sv_cheats and related commands", (CheckFlags(client, "n") ? "x" : ""));
	menu.AddItem("n", strvar);
	Format(strvar, 64, "[%s]Flag o: custom1", (CheckFlags(client, "o") ? "x" : ""));
	menu.AddItem("o", strvar);
	Format(strvar, 64, "[%s]Flag p: custom2", (CheckFlags(client, "p") ? "x" : ""));
	menu.AddItem("p", strvar);
	Format(strvar, 64, "[%s]Flag q: custom3", (CheckFlags(client, "q") ? "x" : ""));
	menu.AddItem("q", strvar);
	Format(strvar, 64, "[%s]Flag r: custom4", (CheckFlags(client, "r") ? "x" : ""));
	menu.AddItem("r", strvar);
	Format(strvar, 64, "[%s]Flag s: custom5", (CheckFlags(client, "s") ? "x" : ""));
	menu.AddItem("s", strvar);
	Format(strvar, 64, "[%s]Flag t: custom6", (CheckFlags(client, "t") ? "x" : ""));
	menu.AddItem("t", strvar);
	Format(strvar, 64, "[%s]Flag z: root", (CheckFlags(client, "z") ? "x" : ""));
	menu.AddItem("z", strvar);
	menu.AddItem("1", "Save these flags");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, iPage, 0);
}

bool CheckFlags(int client, char[] flag){
	return StrContains(regFlags[client], flag) != -1;
}

int MenuHandler_Flags(Menu menu, MenuAction action, int client, int param2){
	switch(action){
		case MenuAction_End: delete menu;
		case MenuAction_Cancel: if(param2 == -6) ShowPlayer(client);
		case MenuAction_Select:{
			int iPage;
			switch(param2){
				case 0,1,2,3,4,5,6: iPage = 0;
				case 7,8,9,10,11,12,13: iPage = 7;
				case 14,15,16,17,18,19,20: iPage = 14;
				default: iPage = 21;
			}	
			char sInfo[12];
			menu.GetItem(param2, sInfo, 12);
			if (!StrEqual(sInfo, "1")){
				if(CheckFlags(client, sInfo))
					ReplaceString(regFlags[client], 64, sInfo, "");
				else
					Format(regFlags[client], 64, "%s%s", regFlags[client], sInfo);
				ChooseFlagMenu(client, iPage);
			}
			else{
				PrintToChat(client, "%s Succesfully changed %s's flags to %s\"%s\".", PREFIX, regName[client], GREENYELLOW, regFlags[client]);
				UpdateAdmin(client);
			}
		}
	}
}

void UpdateAdmin(int client){
	char strvar[64];
	bool found;
	Alphabetize(regFlags[client], 64);
	KeyValues KvAdmins = new KeyValues("Admins");
	KvAdmins.ImportFromFile("addons/sourcemod/configs/admins.cfg");
	KvAdmins.GotoFirstSubKey();
	do{
		KvAdmins.GetString("identity", strvar, 64);
		if(StrEqual(strvar, regSteamid[client])){
			if(regName[client][0])
				KvAdmins.SetSectionName(regName[client]);
			if(regGroup[client][0] || regFlags[client][0]){
				KvAdmins.SetString("group", regGroup[client]);
				KvAdmins.SetString("flags", regFlags[client]);
			}
			else
				KvAdmins.DeleteThis();
			found = true;
			break;
		}
	}
	while(KvAdmins.GotoNextKey());
	KvAdmins.Rewind();
	if(!found && regName[client][0]){
		if(KvAdmins.JumpToKey(regName[client], false))
			ReplyToCommand(client, "[SM] This name is already used");
		else{
			KvAdmins.JumpToKey(regName[client], true);
			KvAdmins.SetString("auth", "steam");
			KvAdmins.SetString("identity", regSteamid[client]);
			KvAdmins.SetString("group", regGroup[client]);
			KvAdmins.SetString("flags", regFlags[client]);
		}
	}
	KvAdmins.Rewind();
	KvAdmins.ExportToFile("addons/sourcemod/configs/admins.cfg");
	delete KvAdmins;
	DumpAdminCache(AdminCache_Admins, true);
	ShowPlayer(client);
}

void AdminFileMenu(int client){
	char strvar[64], sFileName[64], sFileSteamID[64], sFileGroup[64], sFileFlags[64];
	
	KeyValues KvAdmins = CreateKeyValues("Admins");
	KvAdmins.ImportFromFile("addons/sourcemod/configs/admins.cfg");
	if(!KvAdmins.GotoFirstSubKey()){
		Cmd_Addmin(client, 0);
		PrintToChat(client, "%s No admin in adminlist!", PREFIX);
		return;
	}
	Menu menu = new Menu(MenuHandler_Configs);
	menu.SetTitle("List of all admins of the server");
	do{
		KvAdmins.GetSectionName(sFileName, 64);
		KvAdmins.GetString("identity", sFileSteamID, 64);
		KvAdmins.GetString("group", sFileGroup, 64);
		KvAdmins.GetString("flags", sFileFlags, 64);
		Format(strvar, 64, "%s %s %s %s", sFileName, sFileSteamID, sFileGroup, sFileFlags);
		menu.AddItem(strvar, sFileName);
	}
	while(KvAdmins.GotoNextKey());
	delete KvAdmins;
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

int MenuHandler_Configs(Menu menu, MenuAction action, int client, int param2){
	switch(action){
		case MenuAction_End: delete menu;
		case MenuAction_Cancel: if(param2 == -6) Cmd_Addmin(client, 0);
		case MenuAction_Select:{
			char sInfo[128], strvar[4][32];
			menu.GetItem(param2, sInfo, 128);
			ExplodeString(sInfo, " ", strvar, 4, 32);
			regName[client] = strvar[0];
			regSteamid[client] = strvar[1];
			regGroup[client] = strvar[2];
			regFlags[client] = strvar[3];
			ShowPlayer(client);
		}
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs){
	if(IsValidClient(client)){
		if(biState[client] > 0){
			if(StrEqual(sArgs, "cancel", false)){
				PrintToChat(client, "%s Canceled.", PREFIX);
				if(biState[client] == 3)
					ShowPlayer(client);
				else
					InitialiseCl(client);
			}
			else if(biState[client] == 1){
				if(!strncmp(sArgs, "STEAM_", 6)){
					strcopy(regSteamid[client], 64, sArgs);
					if(!SearchInCfg(client)){
						PrintToChat(client, "%s No admin found, now enter a name for this admin, or type cancel.", PREFIX);
						biState[client]++;
					}
					else{
						PrintToChat(client, "%s This player is in admin list.", PREFIX);
						ShowPlayer(client);
					}
				}
				else
					PrintToChat(client, "%s not valid steamid, retry or type %s\"cancel\".", PREFIX, GREENYELLOW);
			}
			else if(biState[client] > 1){
				strcopy(regName[client], 64, sArgs);
				UpdateAdmin(client);
				ShowPlayer(client);
				PrintToChat(client, "%s Successfully %s the admin%s %s.", PREFIX, biState[client] == 2 ? "created" : "changed", biState[client] == 2 ? "" : "name to", regName[client]);
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

void Alphabetize(char[] inc, int maxlen){
	char[] out = new char[maxlen];
	int car, mincar=-1, index;
	for(int j = 0; j < strlen(inc); j++){
		for(int i = 0; i < strlen(inc); i++){
			car = inc[i];
			if(96 < car < 123 && (mincar == -1 || (car < mincar && mincar != 'z') || car == 'z')){
				mincar = car;
				index = i;
			}
		}
		out[j] = mincar;
		mincar = -1;
		inc[index] = ' ';
	}
	strcopy(inc, maxlen, out);
}

bool IsValidClient(int client){
	return 0 < client <= MaxClients && IsClientInGame(client);
}