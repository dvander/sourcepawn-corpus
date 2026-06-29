#pragma semicolon 1
#include <sourcemod>
#include <regex>
#include <adminmenu>
#include <plugincvars>

#define VERSION 		"0.0.1"
#define ADMINFLAG		ADMINFLAG_ROOT
#define TOGGLE_FLAG	ADMFLAG_ROOT


#define MAX_CVARS 64
#define MAX_CVAR_NAME_LENGTH 64
#define MAX_PLUGIN_NAME_LENGTH 64

new Handle:g_hTrieData;
new Handle:g_hArrayPlugins;

new Handle:g_hTopMenu = INVALID_HANDLE;

new g_iPage[MAXPLAYERS+1] = {0,...};
new String:g_sPlugin[MAXPLAYERS+1][MAX_PLUGIN_NAME_LENGTH+1];

new bool:g_bExpectChat[MAXPLAYERS+1] = {false, ...};
new bool:g_bChangedCvar[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo =
{
	name 		= "tReconfigure",
	author 		= "Thrawn",
	description = "--reconfigure your plugins cvars",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_treconfigure_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hTrieData = CreateTrie();
	g_hArrayPlugins = CreateArray(MAX_PLUGIN_NAME_LENGTH);

	AddCommandListener(CmdListener_Say, "say");
	AddCommandListener(CmdListener_Say, "say_team");

	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {
		OnAdminMenuReady(topmenu);
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice*/
	if (topmenu == g_hTopMenu) {
		return;
	}

	/* Save the Handle */
	g_hTopMenu = topmenu;

	new TopMenuObject:topMenuServerCommands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_SERVERCOMMANDS);
	AddToTopMenu(g_hTopMenu, "sm_treconfigure_refresh", TopMenuObject_Item, AdminMenu_Reconfigure, topMenuServerCommands, "sm_treconfigure_refresh", TOGGLE_FLAG);
}

public AdminMenu_Reconfigure(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
    if (action == TopMenuAction_DisplayOption) {
        Format(buffer, maxlength, "Reconfigure");
    } else if (action == TopMenuAction_SelectOption) {
    	RefreshData();
        CreateMenu_PluginSelection(param);
    }
}

public CreateMenu_PluginSelection(iClient) {
	if(GetArraySize(g_hArrayPlugins) == 0) {
		PrintToChat(iClient, "No configurable plugins found.");
		DisplayTopMenu(g_hTopMenu, iClient, TopMenuPosition_LastCategory);
	} else {
		new Handle:hMenu = CreateMenu(MenuHandler_PluginSelection);

		SetMenuTitle(hMenu, "Select a plugin to configure:");
		SetMenuExitBackButton(hMenu, true);

		for(new i = 0; i < GetArraySize(g_hArrayPlugins); i++) {
			new String:sPlugin[MAX_PLUGIN_NAME_LENGTH+1];
			GetArrayString(g_hArrayPlugins, i, sPlugin, sizeof(sPlugin));

			AddMenuItem(hMenu, sPlugin, sPlugin);
		}

		DisplayMenu(hMenu, iClient, 0);
	}
}


public MenuHandler_PluginSelection(Handle:menu, MenuAction:action, param1, param2) {
	//param1:: client
	//param2:: item

	if(action == MenuAction_Select) {
		new String:sPlugin[MAX_PLUGIN_NAME_LENGTH+1];

		/* Get item info */
		GetMenuItem(menu, param2, sPlugin, sizeof(sPlugin));

		g_iPage[param1] = 0;
		g_sPlugin[param1] = sPlugin;
		CreateMenu_Cvar(param1);

		//if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		//	CreateMenu_PluginSelection(param1);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE) {
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public CreateMenu_Cvar(iClient) {
	new Handle:hArray;
	GetTrieValue(g_hTrieData, g_sPlugin[iClient], hArray);

	if(g_iPage[iClient] < 0)g_iPage[iClient] = GetArraySize(hArray)-1;
	if(g_iPage[iClient] > GetArraySize(hArray)-1)g_iPage[iClient] = 0;

	new Handle:hTrie = GetArrayCell(hArray, g_iPage[iClient]);

	new String:sName[MAX_CVAR_NAME_LENGTH+1];
	GetTrieString(hTrie, "name", sName, sizeof(sName));

	new Handle:hConVar = FindConVar(sName);

	new String:sDescription[1024];
	GetTrieString(hTrie, "desc", sDescription, sizeof(sDescription));

	new String:sValue[1024];
	GetConVarString(hConVar, sValue, sizeof(sValue));
	Format(sValue, sizeof(sValue), "Currently: %s", sValue);

	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, sName);
	DrawPanelText(hPanel, sDescription);

	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
	DrawPanelText(hPanel, sValue);

	new Float:fLower = -1.0;
	if(GetConVarBounds(hConVar, ConVarBound_Lower, fLower)) {
		decl String:sLower[64];
		Format(sLower, sizeof(sLower), "Minimum: %.2f", fLower);
		DrawPanelItem(hPanel, sLower, ITEMDRAW_RAWLINE);
	} else {
		DrawPanelItem(hPanel, " ", ITEMDRAW_RAWLINE);
	}

	new Float:fUpper = -1.0;
	if(GetConVarBounds(hConVar, ConVarBound_Upper, fUpper)) {
		decl String:sLower[64];
		Format(sLower, sizeof(sLower), "Maximum: %.2f", fUpper);
		DrawPanelItem(hPanel, sLower, ITEMDRAW_RAWLINE);
	} else {
		DrawPanelItem(hPanel, " ", ITEMDRAW_RAWLINE);
	}

	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
	if(g_bExpectChat[iClient]) {
		DrawPanelItem(hPanel, "Please say the new value in chat.", ITEMDRAW_RAWLINE);
	} else {
		DrawPanelItem(hPanel, "Change");
	}

	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
	if(g_bChangedCvar[iClient]) {
		// TODO: Think about adding a way to save a change permanently
		//DrawPanelItem(hPanel, "Save");
		DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
	} else {
		DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
	}

	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
	DrawPanelItem(hPanel, "Previous", ITEMDRAW_CONTROL);
	DrawPanelItem(hPanel, "Next", ITEMDRAW_CONTROL);
	DrawPanelItem(hPanel, "Exit");

	SendPanelToClient(hPanel, iClient, PanelHandler_CvarSelection, 60);
}

public PanelHandler_CvarSelection(Handle:menu, MenuAction:action, param1, param2) {
	//param1:: client
	//param2:: item
	if(action == MenuAction_Select) {
		g_bExpectChat[param1] = false;
		g_bChangedCvar[param1] = false;

		if(param2 == 3) {
			g_bExpectChat[param1] = true;
			CreateMenu_Cvar(param1);
		}

		if(param2 == 5) {
			PrintToChat(param1, "Value saved!");
			CreateMenu_Cvar(param1);
		}

		if(param2 == 8) {
			g_iPage[param1]--;
			CreateMenu_Cvar(param1);
		}

		if(param2 == 9) {
			g_iPage[param1]++;
			CreateMenu_Cvar(param1);
		}

		if(param2 == 10) {
			g_iPage[param1] = 0;
			g_sPlugin[param1] = "";
			CreateMenu_PluginSelection(param1);
		}
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE) {
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public Action:CmdListener_Say(client, const String:command[], argc) {
	if(g_bExpectChat[client] && argc > 0) {
		decl String:sValue[128];
		GetCmdArg(1, sValue, sizeof(sValue));
		g_bExpectChat[client] = false;

		new Handle:hArray;
		GetTrieValue(g_hTrieData, g_sPlugin[client], hArray);

		new Handle:hTrie = GetArrayCell(hArray, g_iPage[client]);

		new String:sName[MAX_CVAR_NAME_LENGTH+1];
		GetTrieString(hTrie, "name", sName, sizeof(sName));

		new Handle:hConVar = FindConVar(sName);
		SetConVarString(hConVar, sValue);

		g_bChangedCvar[client] = true;
		CreateMenu_Cvar(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}


// --------------------------------------------------------------
// Plugin convar data maintenance: refresh cvar-list from plugin
// --------------------------------------------------------------
public ClearData() {
	for(new i = 0; i < GetArraySize(g_hArrayPlugins); i++) {
		new String:sPlugin[MAX_PLUGIN_NAME_LENGTH+1];
		GetArrayString(g_hArrayPlugins, i, sPlugin, sizeof(sPlugin));

		new Handle:hArray;
		GetTrieValue(g_hTrieData, sPlugin, hArray);

		for(new j = 0; j < GetArraySize(hArray); j++) {
			new Handle:hTrie = GetArrayCell(hArray, j);
			CloseHandle(hTrie);
		}
		CloseHandle(hArray);
	}

	ClearArray(g_hArrayPlugins);
	ClearTrie(g_hTrieData);
}

public RefreshData() {
	ClearData();

	new Handle:hPluginIterator = GetPluginIterator();

	while(MorePlugins(hPluginIterator)) {
		new Handle:hPlugin = ReadPlugin(hPluginIterator);

		if(hPlugin != INVALID_HANDLE) {
			new String:sPlugin[255];
			if(!GetPluginInfo(hPlugin, PlInfo_Name, sPlugin, sizeof(sPlugin))) {
				GetPluginFilename(hPlugin, sPlugin, sizeof(sPlugin));
			}

			new Handle:hList = GetConVarList(hPlugin);
			if(hList == INVALID_HANDLE)continue;

			new bool:bFoundSth = false;
			new Handle:hArray = CreateArray();

			new Handle:hConVarIterator = GetConVarListIterator(hList);
			while(MoreConvars(hConVarIterator)) {
				new Handle:hConVar = ReadConvar(hConVarIterator);
				if(GetConVarFlags(hConVar) & FCVAR_DONTRECORD)continue;

				new String:sConVarName[64];
				new String:sConVarDescription[128];

				GetConVarName(hConVar, sConVarName, sizeof(sConVarName));
				GetConVarDescription(hConVar, sConVarDescription, sizeof(sConVarDescription));

				new String:sConVarValue[128];
				GetConVarString(hConVar, sConVarValue, sizeof(sConVarValue));

				new Handle:hTrieCvar = CreateTrie();
				SetTrieString(hTrieCvar, "name", sConVarName);
				SetTrieString(hTrieCvar, "value", sConVarValue);
				SetTrieString(hTrieCvar, "desc", sConVarDescription);

				PushArrayCell(hArray, hTrieCvar);
				bFoundSth = true;
			}
			CloseHandle(hConVarIterator);

			if(bFoundSth) {
				SetTrieValue(g_hTrieData, sPlugin, hArray);
				PushArrayString(g_hArrayPlugins, sPlugin);
			}
		}
	}

	CloseHandle(hPluginIterator);
}