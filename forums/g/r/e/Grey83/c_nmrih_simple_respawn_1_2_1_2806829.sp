#pragma newdecls required
#pragma semicolon 1

#include <adminmenu>
#include <sdktools>

#define SPAWN_GRACE_MAX 99999

enum
{
	I_Nuke,
	I_FreezePls,
	I_UnfreezePls,
	I_FreezeNPCs,
	I_UnfreezeNPCs,
	I_Restart,

	I_Total
};

static const char INPUT[][] =
{
	"NukePlayers",
	"FreezeAllPlayers",
	"UnfreezeAllPlayers",
	"FreezeAllNPCs",
	"UnfreezeAllNPCs",
	"RestartRound"
};

TopMenu g_hTopMenu;

ConVar g_hCvarsEnable;
bool g_bEnable = true;
bool g_bFromAdminMenu[MAXPLAYERS + 1];

ConVar sv_spawn_grace_objectivecount;
int sv_spawn_grace_objectivecount_default;

public Plugin myinfo =
{
	name		= "NMRiH respawn player",
	author		= "Mostten",
	description	= "NMRiH respawn player",
	version		= "1.2.1 (rewritten by Grey83)",
	url			= "https://forums.alliedmods.net/showthread.php?p=2548908"
};

public void OnPluginStart(){
	LoadTranslations("nmrih.respawn.phrases");

	RegAdminCmd("sm_rsp",				Command_RespawnMenu, ADMFLAG_GENERIC, "NMRiH respawn menu");
	RegAdminCmd("sm_rspme",				Command_RespawnSelf, ADMFLAG_GENERIC, "NMRiH respawn self");
	RegAdminCmd("sm_rspall",			Command_RespawnAll, ADMFLAG_GENERIC, "NMRiH respawn all players");
	RegAdminCmd("sm_rsplist",			Command_RespawnList, ADMFLAG_GENERIC, "NMRiH respawn player");
	RegAdminCmd("sm_killall",			Command_NukePlayers, ADMFLAG_GENERIC, "Kills all players, then ends the round");
	RegAdminCmd("sm_freezeplayers",		Command_FreezeAllPlayers, ADMFLAG_GENERIC, "Freezes all players");
	RegAdminCmd("sm_unfreezeplayers",	Command_UnfreezeAllPlayers, ADMFLAG_GENERIC, "Unfreezes all players");
	RegAdminCmd("sm_freezezombies",		Command_FreezeAllNPCs, ADMFLAG_GENERIC, "Freezes all NPCs");
	RegAdminCmd("sm_unfreezezombies",	Command_UnfreezeAllNPCs, ADMFLAG_GENERIC, "Unfreezes all NPCs");
	RegAdminCmd("sm_restround",			Command_RestartRound, ADMFLAG_GENERIC, "Restarts round immediately");

	sv_spawn_grace_objectivecount_default = (sv_spawn_grace_objectivecount = FindConVar("sv_spawn_grace_objectivecount")).IntValue;
	sv_spawn_grace_objectivecount.AddChangeHook(OnConVarChanged);
	sv_spawn_grace_objectivecount_default = sv_spawn_grace_objectivecount.IntValue;

	g_hCvarsEnable = CreateConVar("nmrih_simple_respawn_enable", g_bEnable ? "1" : "0", "Allow users to use the Respawn: 1.Enable 0.Disable", _, true, _, true, 1.0);
	g_hCvarsEnable.AddChangeHook(OnConVarChanged);
	g_bEnable = g_hCvarsEnable.BoolValue;
}

public void OnAllPluginsLoaded()
{
	TopMenu topmenu;
	if(LibraryExists("adminmenu") && (topmenu = GetAdminTopMenu())) OnAdminMenuReady(topmenu);
}

public void OnLibraryRemoved(const char[] name)
{
	if(!strcmp(name, "adminmenu")) g_hTopMenu = null;
}

public void OnConfigsExecuted(){
	if(g_bEnable) sv_spawn_grace_objectivecount.IntValue = SPAWN_GRACE_MAX;
}

public void OnAdminMenuReady(Handle aTopMenu){
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
	if(topmenu == g_hTopMenu){
		return;
	}

	g_hTopMenu = topmenu;
	TopMenuObject player_commands = g_hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
	if(player_commands != INVALID_TOPMENUOBJECT){
		g_hTopMenu.AddItem("sm_rsp", AdminMenu_Respawn, player_commands, "sm_rsp", ADMFLAG_GENERIC);
	}
}

public void AdminMenu_Respawn(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength){
	switch(action){
		case TopMenuAction_DisplayOption:	FormatEx(buffer, maxlength, "%T", "Admin Menu Item", client);
		case TopMenuAction_SelectOption:	TopMenuShowToClient(client, true);
	}
}

public void OnConVarChanged(ConVar hConVar, const char[] szOldValue, const char[] szNewValue){
	if(hConVar == g_hCvarsEnable){
		if(!(g_bEnable = hConVar.BoolValue)){
			sv_spawn_grace_objectivecount.IntValue = sv_spawn_grace_objectivecount_default;
		}
	}else if(g_bEnable && hConVar == sv_spawn_grace_objectivecount){
		sv_spawn_grace_objectivecount.IntValue = SPAWN_GRACE_MAX;
	}
}

public Action Command_RespawnSelf(int client, int args){
	if(g_bEnable) RespawnClient(client);
	return Plugin_Handled;
}

public Action Command_RespawnAll(int client, int args){
	if(g_bEnable) RespawnAll();
	return Plugin_Handled;
}

public Action Command_RespawnList(int client, int args){
	if(g_bEnable) RespawnMenuShowToClient(client);
	return Plugin_Handled;
}

public Action Command_NukePlayers(int client, int args){
	if(g_bEnable) AcceptGameStateInput(I_Nuke);
	return Plugin_Handled;
}

public Action Command_FreezeAllPlayers(int client, int args){
	if(g_bEnable) AcceptGameStateInput(I_FreezePls);
	return Plugin_Handled;
}

public Action Command_UnfreezeAllPlayers(int client, int args){
	if(g_bEnable) AcceptGameStateInput(I_FreezePls);
	return Plugin_Handled;
}

public Action Command_FreezeAllNPCs(int client, int args){
	if(g_bEnable) AcceptGameStateInput(I_FreezeNPCs);
	return Plugin_Handled;
}

public Action Command_UnfreezeAllNPCs(int client, int args){
	if(g_bEnable) AcceptGameStateInput(I_UnfreezeNPCs);
	return Plugin_Handled;
}

public Action Command_RestartRound(int client, int args){
	if(g_bEnable) AcceptGameStateInput(I_Restart);
	return Plugin_Handled;
}

public Action Command_RespawnMenu(int client, int args){
	if(g_bEnable) TopMenuShowToClient(client);
	return Plugin_Handled;
}

void TopMenuShowToClient(int client, bool fromAdminMenu = false){
	if(!IsValidClient(client))
		return;

	Menu hMenu = new Menu(MenuHandle_RespawnTop);
	if(hMenu){
		hMenu.SetTitle("%t", "Admin Menu Item");
		char name[64];
		FormatEx(name, sizeof(name), "%T", "Menu Item Respawn", client);
		hMenu.AddItem("", name);	// RespawnPlayers
		FormatEx(name, sizeof(name), "%T", "Menu Item Respawn self", client);
		hMenu.AddItem("", name, IsPlayerAlive(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);	// RespawnSelf
		FormatEx(name, sizeof(name), "%T", "Menu Item Respawn All", client);
		hMenu.AddItem("", name);	// RespawnAllPlayers
		FormatEx(name, sizeof(name), "%T", "Menu Item Nuke Players", client);
		hMenu.AddItem("", name);	// KillAllPlayers
		FormatEx(name, sizeof(name), "%T", "Menu Item Freeze Players", client);
		hMenu.AddItem("", name);	// FreezeAllPlayers
		FormatEx(name, sizeof(name), "%T", "Menu Item Unfreeze Players", client);
		hMenu.AddItem("", name);	// UnfreezeAllPlayers
		FormatEx(name, sizeof(name), "%T", "Menu Item Freeze Zombies", client);
		hMenu.AddItem("", name);	// FreezeAllZombies
		FormatEx(name, sizeof(name), "%T", "Menu Item Unfreeze zombies", client);
		hMenu.AddItem("", name);	// UnfreezeAllZombies
		FormatEx(name, sizeof(name), "%T", "Menu Item Restart Round", client);
		hMenu.AddItem("", name);	// RestartRound
		if((g_bFromAdminMenu[client] = fromAdminMenu)){
			hMenu.ExitBackButton = true;
		}else{
			hMenu.ExitButton = true;
		}
		hMenu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuHandle_RespawnTop(Menu menu, MenuAction action, int client, int select){
	switch(action){
		case MenuAction_Select:{
			switch(select){
				case 0: RespawnMenuShowToClient(client);
				case 1: RespawnClient(client);
				case 2: RespawnAll();
				default:AcceptGameStateInput(select - 3);
			}
		}
		case MenuAction_Cancel:{
			if(select == MenuCancel_ExitBack && g_hTopMenu && IsValidClient(client)){
				g_hTopMenu.Display(client, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:{
			delete menu;
		}
	}
	return 0;
}

void RespawnMenuShowToClient(int client){
	if(!IsValidClient(client))
		return;

	Menu hMenu = new Menu(MenuHandle_RespawnPlayers);
	if(hMenu){
		hMenu.SetTitle("%t", "Menu Item Respawn");
		char item[12], name[32];
		for(int player = 1; player <= MaxClients; player++) if(IsValidClient(player) && !IsPlayerAlive(player)){
			Format(name, sizeof(name), "%N", player);
			Format(item, sizeof(item), "%d", GetClientUserId(player));
			hMenu.AddItem(item, name);
		}
		if(!hMenu.ItemCount) hMenu.AddItem("", "- - -");
		hMenu.ExitBackButton = true;
		hMenu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuHandle_RespawnPlayers(Menu menu, MenuAction action, int client, int select){
	switch(action){
		case MenuAction_Select:{
			char szPlayer[12];
			menu.GetItem(select, szPlayer, sizeof(szPlayer));
			int player = GetClientOfUserId(StringToInt(szPlayer));
			RespawnClient(player);
			RespawnMenuShowToClient(client);
		}
		case MenuAction_Cancel:{
			if(select == MenuCancel_ExitBack) TopMenuShowToClient(client, g_bFromAdminMenu[client]);
		}
		case MenuAction_End:{
			delete menu;
		}
	}
	return 0;
}

bool IsValidClient(int client){
	return 0 < client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

int GetGameStateEntity(){
	int nmrih_game_state = -1;
	while((nmrih_game_state = FindEntityByClassname(nmrih_game_state, "nmrih_game_state")) != -1)
		return nmrih_game_state;

	if((nmrih_game_state = CreateEntityByName("nmrih_game_state")) != -1 && DispatchSpawn(nmrih_game_state))
		return nmrih_game_state;

	return -1;
}

bool RespawnClient(int client){
	if(!IsValidClient(client) || IsPlayerAlive(client))
		return false;

	int state = GetGameStateEntity();
	if(state != -1){
		SetVariantString("!activator");
		return AcceptEntityInput(state, "RespawnPlayer", client);
	}
	return false;
}

int RespawnAll(){
	int count = 0;
	for(int client = 1; client <= MaxClients; client++) if(RespawnClient(client)) count++;
	return count;
}

bool AcceptGameStateInput(int type){
	int state = GetGameStateEntity();
	return state != -1 && AcceptEntityInput(state, INPUT[type]);
}