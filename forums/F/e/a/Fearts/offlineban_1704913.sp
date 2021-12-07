/**
-License:

SB Offline Bans - SourceMod Plugin
Copyright (C) 2011-2012 B.D.A.K. Koch

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

As a special exception, AlliedModders LLC gives you permission to link the
code of this program (as well as its derivative works) to "Half-Life 2," the
"Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
by the Valve Corporation. You must obey the GNU General Public License in
all respects for all other code used. Additionally, AlliedModders LLC grants
this exception to all derivative works. AlliedModders LLC defines further
exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
or <http://www.sourcemod.net/license.php>.

---------------------------------------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <topmenus>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#define MAX_STEAMID_LENGTH 32
#define MAX_IP_LENGTH 64

new Handle:g_Name = INVALID_HANDLE;
new Handle:g_SteamID = INVALID_HANDLE;
new Handle:g_IP = INVALID_HANDLE;
new Handle:g_adminMenu = INVALID_HANDLE;

#define PLUGIN_NAME "Offline Ban list"
#define PLUGIN_AUTHOR "1Swat2KillThemAll"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "1.0.0 (GNU/GPLv3)"
#define PLUGIN_URL ""
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	g_Name = CreateArray(MAX_NAME_LENGTH);
	g_SteamID = CreateArray(MAX_STEAMID_LENGTH);
	g_IP = CreateArray(MAX_IP_LENGTH);

	new Handle:adminMenu = LibraryExists("adminmenu") ? GetAdminTopMenu() : INVALID_HANDLE;
	if (adminMenu != INVALID_HANDLE) {
		OnAdminMenuReady(adminMenu);
	}
}

public OnMapStart() {
	ClearArray(g_Name);
	ClearArray(g_SteamID);
	ClearArray(g_IP);
}

public OnClientPostAdminCheck(client) {
	if (!IsClientInGame(client) || IsFakeClient(client)) {
		return;
	}

	decl String:steamID[MAX_STEAMID_LENGTH];
	GetClientAuthString(client, steamID, sizeof(steamID));
	new index = FindStringInArray(g_SteamID, steamID);

	if (index != -1) {
		RemoveFromArray(g_Name, index);
		RemoveFromArray(g_SteamID, index);
		RemoveFromArray(g_IP, index);
	}
}

public OnClientDisconnect(client) {
	if (!IsClientInGame(client) || IsFakeClient(client)) {
		return;
	}

	new AdminId:adminId = GetUserAdmin(client);
	if (adminId != INVALID_ADMIN_ID) {
		if (GetAdminImmunityLevel(adminId) > 0) {
			return;
		}
	}

	decl String:buffer[MAX_NAME_LENGTH];
	GetClientName(client, buffer, sizeof(buffer));
	PushArrayString(g_Name, buffer);
	GetClientAuthString(client, buffer, sizeof(buffer));
	PushArrayString(g_SteamID, buffer);
	GetClientIP(client, buffer, sizeof(buffer));
	PushArrayString(g_IP, buffer);
}

public OnLibraryRemoved(const String:name[]) {
	if (StrEqual(name, "adminmenu")) {
		g_adminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topMenu) {
	if (topMenu == g_adminMenu) {
		return;
	}

	new TopMenuObject:category = AddToTopMenu(topMenu, "OfflineBans_Cat", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT, "commander_management_nd", ADMFLAG_BAN);

	AddToTopMenu(topMenu, "OfflineBans_ViewPlayers_Item", TopMenuObject_Item, AdminMenuHandler_ShowBanList, category, "", ADMFLAG_BAN);

	g_adminMenu = topMenu;
}

public CategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayTitle) {
		Format(buffer, maxlength, "Offline Bans:");
	}
	else if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Offline Bans");
	}
}

public AdminMenuHandler_ShowBanList(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "View recently disconnected players");
	}
	else if (action == TopMenuAction_SelectOption) {
		ShowBanList(param);
	}
}

ShowBanList(client) {
	new Handle:menu = CreateMenu(MenuHandler_BanList);

	SetMenuTitle(menu, "Select Player:");
	decl String:name[MAX_NAME_LENGTH],
		String:steamID[MAX_STEAMID_LENGTH];
	for (new i = 0, size = GetArraySize(g_SteamID); i < size; i++) {
		GetArrayString(g_Name, i, name, sizeof(name));
		GetArrayString(g_SteamID, i, steamID, sizeof(steamID));
		AddMenuItem(menu, steamID, name);
	}
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "cancel", "Cancel");
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_BanList(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		decl String:name[MAX_NAME_LENGTH],
			String:steamID[MAX_STEAMID_LENGTH];
		GetMenuItem(menu, param2, steamID, sizeof(steamID), _, name, sizeof(name));

		if (StrEqual(steamID, "") || StrEqual(steamID, "cancel")) {
			RedisplayAdminMenu(g_adminMenu, param1);
		}
		else {
			new index = FindStringInArray(g_SteamID, steamID);

			if (index == -1) {
				PrintToChat(param1, "[SM] Player '%s' is no longer valid.", name);
				ShowBanList(param1);
				return;
			}

			ShowBanMenu(param1, name, steamID);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

ShowBanMenu(client, const String:name[], const String:steamID[]) {
	static const String:times_display[6][] = {
		"Permanent",
		"5 minutes",
		"30 minutes",
		"1 hour",
		"1 day",
		"1 week"
	};
	static const times[6] = {
		0,
		5,
		30,
		60,
		1440,
		34560,
	};

	new Handle:menu = CreateMenu(MenuHandler_BanMenu);

	SetMenuTitle(menu, "%s: %s", steamID, name);
	decl String:info[MAX_NAME_LENGTH*4];
	for (new i = 0; i < 6; i++) { 
		Format(info, sizeof(info), "%s|%i", steamID, times[i]);
		AddMenuItem(menu, info, times_display[i]);
	}
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "cancel", "Cancel");
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_BanMenu(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		decl String:info[MAX_NAME_LENGTH*2];
		GetMenuItem(menu, param2, info, sizeof(info));

		if (StrEqual(info, "") || StrEqual(info, "cancel")) {
			ShowBanList(param1);
			return;
		}

		decl String:data[2][MAX_NAME_LENGTH];

		ExplodeString(info, "|", data, sizeof(data), sizeof(data[]));
		new index = FindStringInArray(g_SteamID, data[0]);

		if (index == -1) {
			PrintToChat(param1, "[SM] Steamid '%s' is no longer valid.", data[0]);
			ShowBanList(param1);
			return;
		}

		new time = StringToInt(data[1]);

		decl String:steamID[MAX_STEAMID_LENGTH],
			String:name[MAX_NAME_LENGTH],
			String:ip[MAX_IP_LENGTH];

		GetArrayString(g_Name, index, name, sizeof(name));
		GetArrayString(g_IP, index, ip, sizeof(ip));

		GetClientAuthString(param1, steamID, sizeof(steamID));

		ServerCommand("sm_addban %i \"%s\" \"%N - %s - %s - %s\"", time, data[0], param1, steamID, name, ip);

		RemoveFromArray(g_Name, index);
		RemoveFromArray(g_SteamID, index);
		RemoveFromArray(g_IP, index);

		RedisplayAdminMenu(g_adminMenu, param1);
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}