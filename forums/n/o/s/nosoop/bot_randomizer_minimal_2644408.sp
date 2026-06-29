/**
 * Sourcemod 1.7 Plugin Template
 */
#pragma semicolon 1
#include <sourcemod>

#include <tf2items>
#include <tf_econ_data>

#pragma newdecls required

static TFClassType s_ContextPlayerClass = TFClass_Unknown;

public Action TF2Items_OnGiveNamedItem(int client, char[] className, int defindex,
		Handle &item) {
	static Handle s_Item;
	if (!s_Item) {
		// s_Item = TF2Items_CreateItem(OVERRIDE_ALL | PRESERVE_ATTRIBUTES);
		s_Item = TF2Items_CreateItem(OVERRIDE_ALL | PRESERVE_ATTRIBUTES);
	}
	
	PrintToServer("item check");
	if (item) {
		return Plugin_Continue;
	}
	
	item = s_Item;
	
	s_ContextPlayerClass = TF2_GetPlayerClass(client);
	
	ArrayList itemList = TF2Econ_GetItemList(FilterSlotItems,
			TF2Econ_GetItemSlot(defindex, s_ContextPlayerClass));
	
	int newDefIndex = itemList.Get(GetRandomInt(0, itemList.Length - 1));
	
	delete itemList;
	
	char cname[64];
	TF2Econ_GetItemClassName(newDefIndex, cname, sizeof(cname));
	TF2Econ_TranslateWeaponEntForClass(cname, sizeof(cname), s_ContextPlayerClass);
	
	int iMinLevel, iMaxLevel;
	TF2Econ_GetItemLevelRange(newDefIndex, iMinLevel, iMaxLevel);
	
	TF2Items_SetItemIndex(s_Item, newDefIndex);
	TF2Items_SetClassname(s_Item, cname);
	TF2Items_SetLevel(s_Item, GetRandomInt(iMinLevel, iMaxLevel));
	TF2Items_SetQuality(s_Item, 2);
	
	PrintToServer("%N item: %08x (def %d, cname %s)", client, s_Item, newDefIndex, cname);
	return Plugin_Changed;
}

public bool FilterSlotItems(int defindex, int slot) {
	return TF2Econ_GetItemSlot(defindex, s_ContextPlayerClass) == slot;
}
