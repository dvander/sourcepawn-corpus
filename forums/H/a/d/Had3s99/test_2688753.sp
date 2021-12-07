#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define VERSION		"1.0"
#define SPEC		1
#define TEAM1		2
#define TEAM2		3

Handle g_Health;
Handle g_Armor;

int g_PlayerRespawn[MAXPLAYERS+1];

public Plugin myinfo = {
    name = "VIP Plugin",
    author = "Hk",
    description = "",
    version = VERSION,
    url = ""
};

public void OnPluginStart() {
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	CreateConVar("sm_vip_version", VERSION, "VIP Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Health = CreateConVar("sm_vip_health", "100", "HP On Spawn");
	g_Armor = CreateConVar("sm_vip_armor", "100", "Armor On Spawn");
	
	RegConsoleCmd("sm_vip", CMD_Vip);
	
	AutoExecConfig(true, "sm_vip");
}

public Action CMD_Vip(int client, int args) {
	if(!isVip(client)) {
		PrintToChat(client, "\x04[ IRG ]\x01 You Are Not \x03VIP\x01.");
		return Plugin_Handled;
	}

	if (IsClientInGame(client)) {
		Handle VMenu = CreateMenu(VipMenu);
		SetMenuTitle(VMenu, "\n.::VIP MENU::.");
		AddMenuItem(VMenu, "AK47", "AK47+Deagle");
		AddMenuItem(VMenu, "M4A4", "M4A4_Deagle");
		AddMenuItem(VMenu, "M4A1", "M4A1+Deagle");
		AddMenuItem(VMenu, "FAMAS", "Famas+Deagle+zeus+Medishot");
		AddMenuItem(VMenu, "GALIL", "Galil+Deagle+zeus+Medishot");
		AddMenuItem(VMenu, "SG556", "SG556+Deagle+zeus+Medishot");
		AddMenuItem(VMenu, "AUG", "AUG+Deagle+zeus+Medishot");
		AddMenuItem(VMenu, "SCOUT", "Scout+Deagle+zeus+Medishot");
		AddMenuItem(VMenu, "AWP", "Awp+Deagle+zeus+Medishot");
		AddMenuItem(VMenu, "WALLHACK", "Wallhack_Grenade");
		SetMenuExitButton(VMenu, true);
		DisplayMenu(VMenu, client, 0);
    }
	return Plugin_Continue;
}

public int VipMenu(Handle VMenu, MenuAction action, int client, int position) {
    if(action == MenuAction_Select && isVip(client)) {
        char item[20];
        GetMenuItem(VMenu, position, item, sizeof(item));
        
        if(StrEqual(item, "AK47")) {
            GivePlayerItem(client, "weapon_ak47");
            GivePlayerItem(client, "weapon_deagle");
        }    
        else if(StrEqual(item, "M4A4")) {
            GivePlayerItem(client, "weapon_m4a1");
            GivePlayerItem(client, "weapon_deagle");
        }
        else if(StrEqual(item, "M4A1")) {
            GivePlayerItem(client, "weapon_m4a1_silencer");
            GivePlayerItem(client, "weapon_deagle");
        }
        else if(StrEqual(item, "FAMAS")) {
			GivePlayerItem(client, "weapon_famas");
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
        }
        else if(StrEqual(item, "GALIL")) {
			GivePlayerItem(client, "weapon_galilar");
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
        }
        else if(StrEqual(item, "SG556")) {
			GivePlayerItem(client, "weapon_sg556");
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
        }
        else if(StrEqual(item, "AUG")) {
			GivePlayerItem(client, "weapon_aug");
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
        }
        else if(StrEqual(item, "SCOUT")) {
			GivePlayerItem(client, "weapon_ssg08");
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
        }
        else if(StrEqual(item, "AWP")) {
			GivePlayerItem(client, "weapon_awp");
			GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
        }
        else if(StrEqual(item, "WALLHACK")) {
			GivePlayerItem(client, "weapon_tagrenade");
		}
	}
    else if(action == MenuAction_End) {
        CloseHandle(VMenu);
    }
}

public bool OnClientConnect(int client, char []Reject, int Len) {
    if (IsClientInGame(client))
        g_PlayerRespawn[client] = 3;
    else 
    	g_PlayerRespawn[client] = 0;
}  

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(client) > CS_TEAM_SPECTATOR && IsClientInGame(client) && isVip(client)) {
		if(GameRules_GetProp("m_totalRoundsPlayed") >= 3) {
			//VIP(client, 0); // Use console command callback
		}

		SetEntProp(client, Prop_Data, "m_iHealth", GetConVarInt(g_Health));
		SetEntProp(client, Prop_Send, "m_ArmorValue", GetConVarInt(g_Armor));
	}
	return Plugin_Handled;
}

stock bool isVip(int client) {
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1) return true;
	else return false;
}