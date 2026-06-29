#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "[TF2] Select Melee",
	author      = "ThatKidWhoGames",
	description = "Switches the weapon of players to their melee when spawning or using a resupply cabinet.",
	version     = "1.0.0",
	url         = "https://forums.alliedmods.net/showthread.php?t=349732"
};

public void OnPluginStart() {
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
}

public void Event_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast) {
	RequestFrame(Frame_PostInventoryApplication, event.GetInt("userid"));
}

public void Frame_PostInventoryApplication(any data) {
	int client = GetClientOfUserId(data);
	if (client != 0 && IsClientInGame(client) && IsPlayerAlive(client)) {
		//int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		//if (melee != -1) {
		//	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", melee);
		//	TF2_AddCondition(client, TFCond_Taunting, 0.1); // for some reason, fixes invis.
		//}
		TF2_AddCondition(client, TFCond_Taunting, 0.1);
	}
}