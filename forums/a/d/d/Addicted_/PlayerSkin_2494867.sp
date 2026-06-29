#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.7.1"
#define PLUGIN_AUTHOR "noBrain"
#define MAX_SKIN_PATH 128

ConVar g_cFix = null;

char g_szPlayerSkinPath[MAXPLAYERS+1][MAX_SKIN_PATH];
char g_szPlayerArmPath[MAXPLAYERS+1][MAX_SKIN_PATH];

bool g_bUserHasSkins[MAXPLAYERS+1] = false;
bool g_bUserHasArms[MAXPLAYERS+1];

int SkinTeam[MAXPLAYERS+1];

public Plugin myinfo =  {

	name = "PlayerSkin",
	author = PLUGIN_AUTHOR,
	description = "Allow players to select their skins.",
	version = PLUGIN_VERSION,

};

public void OnPluginStart() {

	HookEvent("player_spawn", PlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", PlayerDisConnect, EventHookMode_PostNoCopy);

	RegConsoleCmd("sm_pskin", Command_PlayerSkin);

	g_cFix = CreateConVar("sm_pg_cFix", "1", "Allow Plugin To Apply An Arm fix on player spawn.")

}

public void OnMapStart() {

	char Arms[128], Skin[128];
	Handle kv = CreateKeyValues("Skins");
	FileToKeyValues(kv, "addons/sourcemod/configs/skin.ini");
	KvGotoFirstSubKey(kv, false);

	do {
	
		KvGetString(kv, "Skin", Skin, sizeof(Skin), "");
		KvGetString(kv, "Arms", Arms, sizeof(Arms), "");

		if(!StrEqual(Arms, "")) {

			PrecacheModel(Arms);

		}

		if(!StrEqual(Arms, "") && !StrEqual(Skin, "")) {

			PrecacheModel(Arms);
			PrecacheModel(Skin);

		}

	} while (KvGotoNextKey(kv, false));

	CloseHandle(kv);

}
public Action PlayerDisConnect(Handle event, const char[] name, bool dontBroadcast) {

	g_bUserHasSkins[GetClientOfUserId(GetEventInt(event, "userid"))] = false;

	return Plugin_Continue;

}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {

	CreateTimer(0.1, SetSkins, GetEventInt(event, "userid"));

}

public Action SetSkins(Handle timer, any userid) {

	int client = GetClientOfUserId(userid);	

	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {

		return Plugin_Stop;

	}

	if(GetConVarBool(g_cFix)) {

		CreateTimer(0.1, GiveGuns, userid);
		StripAllWeapons(client);

	}

	if(g_bUserHasSkins[client] == true && GetClientTeam(client) == SkinTeam[client]) {

		SetEntityModel(client, g_szPlayerSkinPath[client]);

		if(g_bUserHasArms[client] == true) {

			SetEntPropString(client, Prop_Send, "m_szArmsModel", g_szPlayerArmPath[client]);

		} else if(g_bUserHasArms[client] == false) {

			int iTeamID = GetClientTeam(client);
			if(iTeamID == 2) {

				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/ct_arms.mdl");

			} else if(iTeamID == 3) {

				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/ct_arms.mdl");

			}

		}

	}

	return Plugin_Stop;

}

public Action GiveGuns(Handle timer, any userid) {

	int client = GetClientOfUserId(userid);	

	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {

		return Plugin_Stop;

	}

	GivePlayerItem(client, "weapon_knife");

	return Plugin_Stop;

}

public Action Command_PlayerSkin(int client, int args) {

	DisplaySkinMenu(client);

	return Plugin_Continue;

}

stock Action DisplaySkinMenu(int client) {

	char SkinName[32], SkinPath[128], ArmPath[128], UniqueId[32];

	Handle menu = CreateMenu(SkinMenu);
	SetMenuTitle(menu, "Select a Skin");

	Handle kv = CreateKeyValues("Skins");
	FileToKeyValues(kv, "addons/sourcemod/configs/skin.ini");
	KvGotoFirstSubKey(kv, false);

	do {

		KvGetString(kv, "Name", SkinName, sizeof(SkinName));
		KvGetString(kv, "Skin", SkinPath, sizeof(SkinPath));
		KvGetString(kv, "Arms", ArmPath, sizeof(ArmPath));
		KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
		AddMenuItem(menu, UniqueId, SkinName);

	}

	while(KvGotoNextKey(kv, false));
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	SetMenuExitButton(menu, true);
	CloseHandle(kv);

	return Plugin_Continue;

}

public int SkinMenu(Handle menu, MenuAction action, int param1, int param2) {

	char SkinName[32], SkinPath[128], ArmPath[128], UniqueId[32];
	Handle kv = CreateKeyValues("Skins");
	FileToKeyValues(kv, "addons/sourcemod/configs/skin.ini");

	switch (action) {

		case MenuAction_Select: {

			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			KvGotoFirstSubKey(kv, false);

			do {

				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));

				if (StrEqual(item, "def")) {

					g_bUserHasSkins[param1] = false;
					CloseHandle(kv);
					CloseHandle(menu);

				}

				if (StrEqual(item, UniqueId)) {

					int iTeamID = KvGetNum(kv, "Team");

					if(GetClientTeam(param1) != iTeamID) {

						PrintToChat(param1, "[SM] This Selected Skin Is Not For Your Team!");
						return;

					}

					SkinTeam[param1] = iTeamID;
					KvGetString(kv, "Name", SkinName, sizeof(SkinName));
					KvGetString(kv, "Skin", SkinPath, sizeof(SkinPath));
					KvGetString(kv, "Arms", ArmPath, sizeof(ArmPath));
					SetEntityModel(param1, SkinPath);

					if(!StrEqual(ArmPath, "")) {

						SetEntPropString(param1, Prop_Send, "m_szArmsModel", ArmPath);
						g_bUserHasArms[param1] = true;

					} else if(StrEqual(ArmPath, "")) {

						g_bUserHasArms[param1] = false;

					}

					g_bUserHasSkins[param1] = true;
					Format(g_szPlayerSkinPath[param1], sizeof(g_szPlayerSkinPath[]), SkinPath); 
					Format(g_szPlayerArmPath[param1], sizeof(g_szPlayerArmPath[]), ArmPath);

				} else {

					KvGotoNextKey(kv, false);

				}

			} while (!StrEqual(item, UniqueId));

		}

		case MenuAction_End: {

			CloseHandle(kv);
			CloseHandle(menu);
		}

	}

}

stock void StripAllWeapons(int client) {

	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {

		return;

	}

	int weapon;
	for (int i; i < 4; i++) {
	
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1) {
		
			if (IsValidEntity(weapon)) {
			
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill");
				
			}
			
		}
		
	}
	
}