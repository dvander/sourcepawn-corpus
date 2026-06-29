#pragma semicolon 1
#include <sourcemod>
#include <adminmenu>
#undef REQUIRE_PLUGIN
#include <tNoUnlocksPls>
#include <updater>

#define VERSION			"0.4.0"
#define UPDATE_URL    	"http://updates.thrawn.de/tNoUnlocksPls/package.tNoUnlocksPls.menu.cfg"

#define TOGGLE_FLAG	ADMFLAG_ROOT

new Handle:g_hTopMenu = INVALID_HANDLE;

public Plugin:myinfo = {
	name        = "tNoUnlocksPls - AdminMenu",
	author      = "Thrawn",
	description = "Allows easy configuration via adminmenu.",
	version     = VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=140045"
};


public OnPluginStart() {
	CreateConVar("sm_tnounlockspls_menu_version", VERSION, "[TF2] tNoUnlocksPls - AdminMenu", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}

	// Account for late loading
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {
		OnAdminMenuReady(topmenu);
	}
}

public OnLibraryAdded(const String:name[]) {
    if (StrEqual(name, "updater"))Updater_AddPlugin(UPDATE_URL);
}

public OnAdminMenuReady(Handle:topmenu) {
	// Block us from being called twice
	if(topmenu == g_hTopMenu)return;

	// Save the Handle
	g_hTopMenu = topmenu;

	new TopMenuObject:topMenuServerCommands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_SERVERCOMMANDS);
	AddToTopMenu(g_hTopMenu, "sm_toggleunlock", TopMenuObject_Item, AdminMenu_Unlocks, topMenuServerCommands, "sm_toggleunlock", TOGGLE_FLAG);
}

public AdminMenu_Unlocks(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
    if (action == TopMenuAction_DisplayOption) {
        Format(buffer, maxlength, "Unlocks");
    } else if (action == TopMenuAction_SelectOption) {
        BuildUnlockMenu(param, 0);
    }
}

public BuildUnlockMenu(iClient, iPos) {
	if(!LibraryExists("tNoUnlocksPls")) {
		PrintToChat(iClient, "Core plugin is not running!");
		return;
	}
	new Handle:menu = CreateMenu(ChooserMenu_Handler);

	SetMenuTitle(menu, "Enabled:");
	if(tNUP_BlockByDefault())SetMenuTitle(menu, "Disabled:");
	SetMenuExitBackButton(menu, true);

	new Handle:hWeapons = INVALID_HANDLE;
	tNUP_GetWeaponArray(hWeapons);

	new cnt = 0;
	for(new i = 0; i < GetArraySize(hWeapons); i++) {
		new iItemDefinitionIndex = GetArrayCell(hWeapons, i);

		new Handle:hItemTrie = INVALID_HANDLE;
		tNUP_GetItemTrie(iItemDefinitionIndex, hItemTrie);
		new bool:bToggled = tNUP_GetWeaponToggleState(iItemDefinitionIndex);


		new String:sName[128];
		if(!tNUP_GetPrettyName(iItemDefinitionIndex, iClient, sName, sizeof(sName)))continue;

		new String:sEntry[160];
		Format(sEntry, sizeof(sEntry), "%s (%s)", sName, bToggled ? "yes" : "no");

		new String:sIdx[4];
		IntToString(iItemDefinitionIndex, sIdx, 4);

		AddMenuItem(menu, sIdx, sEntry);
		cnt++;
	}

	if(cnt == 0) {
		PrintToChat(iClient, "No weapons found - something must be configured incorrectly.");
		DisplayTopMenu(g_hTopMenu, iClient, TopMenuPosition_LastCategory);
	} else {
		DisplayMenuAtItem(menu, iClient, iPos, 0);
	}
}

public ChooserMenu_Handler(Handle:menu, MenuAction:action, param1, param2) {
	//param1:: client
	//param2:: item

	if(action == MenuAction_Select) {
		new String:sIdx[4];

		// Get item info
		GetMenuItem(menu, param2, sIdx, sizeof(sIdx));
		new iIdx = StringToInt(sIdx);
		tNUP_ToggleItem(iIdx);

		if (IsClientInGame(param1) && !IsClientInKickQueue(param1)) {
			BuildUnlockMenu(param1, GetMenuSelectionPosition());
		}
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE) {
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}