#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

#define CS_SLOT_KNIFE 2

#define PLUGIN_VERSION "1.0"

new Handle:ghCookie = INVALID_HANDLE;
new String:gsKnives[][] = {"weapon_bayonet", "weapon_knife_flip", "weapon_knife_gut", "weapon_knife_karambit", "weapon_knife_m9_bayonet", "weapon_knife_tactical", "weapon_knife_butterfly", "weapon_knifegg"};

new giPlayerKnives[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "NNKnives",
	author = "DQ",
	description = "Adds custom knives",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/profiles/76561198022098921/"
};

public OnPluginStart() {

	RegConsoleCmd("sm_knife", Command_Knife);

	ghCookie = RegClientCookie("NNKnife", "Knife Type", CookieAccess_Protected);

	HookEvent("item_pickup", OnItemPickup, EventHookMode_Post);
}

// This doesn't always work. Maybe some issue with cookie not loading for the plugin yet
// Not a big deal tho
// Maybe it does actually? I don't even remember by now.
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {

	if (late) {
		for (new i = 1;  i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				LoadPlayerData(i);
			}
		}
	}

	return APLRes_Success;
}

public OnClientPostAdminCheck(client) {

	LoadPlayerData(client);
}

public OnClientDisconnect(client) {

	giPlayerKnives[client] = 0;
}

public OnMapStart() {

	for (new i = 1; i <= MaxClients; i++) {
		giPlayerKnives[i] = 0;
	}
}

public Action:Command_Knife(client, args) {

	if (client == 0) {
		return Plugin_Handled;
	}

	if (!IsClientInGame(client)) {
		return Plugin_Handled;
	}

	new Handle:menu = CreateMenu(Menu_Knife);
	SetMenuTitle(menu, "Choose a knife");
	AddMenuItem(menu, "1", "Bayonet");
	AddMenuItem(menu, "2", "Flip");
	AddMenuItem(menu, "3", "Gut");
	AddMenuItem(menu, "4", "Karambit");
	AddMenuItem(menu, "5", "M9 Bayonet");
	AddMenuItem(menu, "6", "Huntsman");
	AddMenuItem(menu, "7", "Butterfly");
	AddMenuItem(menu, "8", "Golden");
	AddMenuItem(menu, "0", "Standart");
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 90);

	return Plugin_Handled;
}

public Menu_Knife(Handle:menu, MenuAction:action, client, param2) {

	if (action == MenuAction_Select) {
		if (!IsClientInGame(client)) {
			return;
		}
		decl String:info[8];
		GetMenuItem(menu, param2, info, sizeof(info));

		new iChoice = StringToInt(info);
		if (giPlayerKnives[client] == iChoice) {
			return;
		}
		
		giPlayerKnives[client] = iChoice;

		decl String:sCookie[8];
		Format(sCookie, sizeof(sCookie), "%d", iChoice);
		SetClientCookie(client, ghCookie, sCookie);

		CreateTimer(0.1, Timer_OnPickUp, client);
	} else if (action == MenuAction_Cancel) {
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public Action:OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast) {

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (giPlayerKnives[client] < 1 || giPlayerKnives[client] > sizeof(gsKnives)) {
		return Plugin_Continue;
	}

	decl String:sWeapon[64];
	GetEventString(event, "item", sWeapon, sizeof(sWeapon));
	if (StrEqual(sWeapon, "knife") || StrEqual(sWeapon, "knife_default_ct") || StrEqual(sWeapon, "knife_default_t")) {
		CreateTimer(0.1, Timer_OnPickUp, client);
		return Plugin_Continue;
	}

	return Plugin_Continue;
}

public Action:Timer_OnPickUp(Handle:timer, any:client) {

	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		new iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		if (iWeapon > 0) {
			if (IsValidEdict(iWeapon)) {
				CS_DropWeapon(client, iWeapon, false, true);
				AcceptEntityInput(iWeapon, "Kill");
			}
		}
		GiveKnife(client, giPlayerKnives[client]);
	}

	return Plugin_Handled;
}

stock GiveKnife(client, knife) {

	if (knife < 0 || knife > sizeof(gsKnives)) {
		return;
	}

	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		if (knife == 0) {
			GivePlayerItem(client, "weapon_knife");
		} else {
			new item = GivePlayerItem(client, gsKnives[knife-1]);
			EquipPlayerWeapon(client, item);
		}
	}
}

stock LoadPlayerData(client) {

	giPlayerKnives[client] = 0;

	decl String:sCookie[32];
	GetClientCookie(client, ghCookie, sCookie, sizeof(sCookie));
	new iKnife = StringToInt(sCookie);
	if (iKnife >= 1 && iKnife <= sizeof(gsKnives)) {
		giPlayerKnives[client] = iKnife;
	}
}