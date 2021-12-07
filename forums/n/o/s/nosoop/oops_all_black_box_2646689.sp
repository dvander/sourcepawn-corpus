#pragma semicolon 1
#include <sourcemod>

#include <tf2_stocks>
#include <tf2items>

#pragma newdecls required

public Action TF2Items_OnGiveNamedItem(int client, char[] className, int defindex,
		Handle &item) {
	static Handle s_Item;
	if (!s_Item) {
		s_Item = TF2Items_CreateItem(OVERRIDE_ITEM_DEF);
	}
	
	if (TF2_GetPlayerClass(client) != TFClass_Soldier) {
		return Plugin_Continue;
	}
	
	if (!StrEqual(className, "tf_weapon_rocketlauncher")) {
		return Plugin_Continue;
	}
	
	item = s_Item;
	
	int newDefIndex = 228;
	
	TF2Items_SetItemIndex(s_Item, newDefIndex);
	
	return Plugin_Changed;
}
