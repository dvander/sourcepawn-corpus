#define PLUGIN_VERSION "0.93"

public Plugin:myinfo = {
	name		= "TF2IDB",
	author	  	= "Bottiger",
	description = "Item Schema Database",
	version	 	= PLUGIN_VERSION,
	url		 	= "http://skial.com"
};

#include <tf2idb>

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:sError[], iErrorSize) {
	CreateNative("TF2IDB_IsValidItemID", Native_IsValidItemID);
	CreateNative("TF2IDB_GetItemName", Native_GetItemName);
	CreateNative("TF2IDB_GetItemClass", Native_GetItemClass);
	CreateNative("TF2IDB_GetItemSlotName", Native_GetItemSlotName);
	CreateNative("TF2IDB_GetItemSlot", Native_GetItemSlot);
	CreateNative("TF2IDB_GetItemQualityName", Native_GetItemQualityName);
	CreateNative("TF2IDB_GetItemQuality", Native_GetItemQuality);
	CreateNative("TF2IDB_GetItemLevels", Native_GetItemLevels);
	CreateNative("TF2IDB_GetItemAttributes", Native_GetItemAttributes);
	CreateNative("TF2IDB_GetItemEquipRegions", Native_GetItemEquipRegions);
	CreateNative("TF2IDB_DoRegionsConflict", Native_DoRegionsConflict);
	CreateNative("TF2IDB_ListParticles", Native_ListParticles);
	CreateNative("TF2IDB_FindItemCustom", Native_FindItemCustom);
	CreateNative("TF2IDB_ItemHasAttribute", Native_ItemHasAttribute);

	RegPluginLibrary("tf2idb");
	return APLRes_Success;
}

new Handle:g_db;

new Handle:g_statement_IsValidItemID;
new Handle:g_statement_GetItemClass;
new Handle:g_statement_GetItemName;
new Handle:g_statement_GetItemSlotName;
new Handle:g_statement_GetItemQualityName;
new Handle:g_statement_GetItemLevels;
new Handle:g_statement_GetItemAttributes;
new Handle:g_statement_GetItemEquipRegions;
new Handle:g_statement_ListParticles;
new Handle:g_statement_DoRegionsConflict;
new Handle:g_statement_ItemHasAttribute;

new Handle:g_slot_mappings;
new Handle:g_quality_mappings;

new Handle:g_id_cache;
new Handle:g_class_cache;
new Handle:g_slot_cache;
new Handle:g_minlevel_cache;
new Handle:g_maxlevel_cache;

public OnPluginStart() {
	CreateConVar("sm_tf2idb_version", PLUGIN_VERSION, "TF2IDB version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);

	decl String:error[255];
	g_db = SQLite_UseDatabase("tf2idb", error, sizeof(error));
	if(g_db == INVALID_HANDLE)
		SetFailState(error);

	#define PREPARE_STATEMENT(%1,%2) %1 = SQL_PrepareQuery(g_db, %2, error, sizeof(error)); if(%1 == INVALID_HANDLE) SetFailState(error);
	
	PREPARE_STATEMENT(g_statement_IsValidItemID, "SELECT id FROM tf2idb_item WHERE id=?")
	PREPARE_STATEMENT(g_statement_GetItemClass, "SELECT class FROM tf2idb_item WHERE id=?")
	PREPARE_STATEMENT(g_statement_GetItemName, "SELECT name FROM tf2idb_item WHERE id=?")
	PREPARE_STATEMENT(g_statement_GetItemSlotName, "SELECT slot FROM tf2idb_item WHERE id=?")
	PREPARE_STATEMENT(g_statement_GetItemQualityName, "SELECT quality FROM tf2idb_item WHERE id=?")
	PREPARE_STATEMENT(g_statement_GetItemLevels, "SELECT min_ilevel,max_ilevel FROM tf2idb_item WHERE id=?")
	PREPARE_STATEMENT(g_statement_GetItemAttributes, "SELECT attribute,value FROM tf2idb_item_attributes WHERE id=?")
	PREPARE_STATEMENT(g_statement_GetItemEquipRegions, "SELECT region FROM tf2idb_equip_regions WHERE id=?")
	PREPARE_STATEMENT(g_statement_ListParticles, "SELECT id FROM tf2idb_particles")
	PREPARE_STATEMENT(g_statement_DoRegionsConflict, "SELECT a.name FROM tf2idb_equip_conflicts a JOIN tf2idb_equip_conflicts b ON a.name=b.name WHERE a.region=? AND b.region=?")
	PREPARE_STATEMENT(g_statement_ItemHasAttribute, "SELECT attribute FROM tf2idb_item a JOIN tf2idb_item_attributes b ON a.id=b.id WHERE a.id=? AND attribute=?")

	g_slot_mappings = CreateTrie();
	SetTrieValue(g_slot_mappings, "primary", TF2ItemSlot_Primary);
	SetTrieValue(g_slot_mappings, "secondary", TF2ItemSlot_Secondary);
	SetTrieValue(g_slot_mappings, "melee", TF2ItemSlot_Melee);
	SetTrieValue(g_slot_mappings, "pda", TF2ItemSlot_PDA1);
	SetTrieValue(g_slot_mappings, "pda2", TF2ItemSlot_PDA2);
	SetTrieValue(g_slot_mappings, "building", TF2ItemSlot_Building);
	SetTrieValue(g_slot_mappings, "head", TF2ItemSlot_Head);
	SetTrieValue(g_slot_mappings, "misc", TF2ItemSlot_Misc);
	SetTrieValue(g_slot_mappings, "taunt", TF2ItemSlot_Taunt);
	SetTrieValue(g_slot_mappings, "action", TF2ItemSlot_Action);

	g_quality_mappings = CreateTrie();
	SetTrieValue(g_quality_mappings, "normal", TF2ItemQuality_Normal);
	SetTrieValue(g_quality_mappings, "rarity4", TF2ItemQuality_Rarity4);
	SetTrieValue(g_quality_mappings, "strange", TF2ItemQuality_Strange);
	SetTrieValue(g_quality_mappings, "unique", TF2ItemQuality_Unique);

	g_id_cache = CreateTrie();
	g_class_cache = CreateTrie();
	g_slot_cache = CreateTrie();
	g_minlevel_cache = CreateTrie();
	g_maxlevel_cache = CreateTrie();

	PrepareCache();

	/*
	decl aids[TF2IDB_MAX_ATTRIBUTES];
	decl Float:values[TF2IDB_MAX_ATTRIBUTES];
	new attributes = TF2IDB_GetItemAttributes(424, aids, values);
	PrintToServer("TF2IDB_ItemHasAttribute: %i", attributes);
	for(new i=0;i<attributes;i++) {
		PrintToServer("aid %i value %f", aids[i], values[i]);
	}
	
	PrintItem(43);
	new Handle:paints = TF2IDB_FindItemCustom("SELECT id FROM tf2idb_item WHERE tool_type='paint_can'");

	for(new i=0;i<GetArraySize(paints);i++) {
		PrintToServer("paint %i", GetArrayCell(paints, i));
	}
	*/
}

PrepareCache() {
	new Handle:queryHandle = SQL_Query(g_db, "SELECT id,class,slot,min_ilevel,max_ilevel FROM tf2idb_item");
	while(SQL_FetchRow(queryHandle)) {
		decl String:slot[TF2IDB_ITEMSLOT_LENGTH];
		decl String:class[TF2IDB_ITEMCLASS_LENGTH];
		decl String:id[16];
		SQL_FetchString(queryHandle, 0, id, sizeof(id));
		SQL_FetchString(queryHandle, 1, class, sizeof(class));
		SQL_FetchString(queryHandle, 2, slot, sizeof(slot));
		new min_level = SQL_FetchInt(queryHandle, 3);
		new max_level = SQL_FetchInt(queryHandle, 4);

		SetTrieValue(g_id_cache, id, 1);
		SetTrieString(g_class_cache, id, class);
		SetTrieString(g_slot_cache, id, slot);
		SetTrieValue(g_minlevel_cache, id, min_level);
		SetTrieValue(g_maxlevel_cache, id, max_level);
	}
	CloseHandle(queryHandle);
}

stock PrintItem(id) {
	new bool:valid = TF2IDB_IsValidItemID(id);
	if(!valid) {
		PrintToServer("Invalid Item %i", id);
		return;
	}

	decl String:name[64];
	TF2IDB_GetItemName(43, name, sizeof(name));

	PrintToServer("%i - %s", id, name);
	PrintToServer("slot %i - quality %i", TF2IDB_GetItemSlot(id), TF2IDB_GetItemQuality(id));

	new min,max;
	TF2IDB_GetItemLevels(id, min, max);
	PrintToServer("Level %i - %i", min, max);
}

public Native_IsValidItemID(Handle:hPlugin, nParams) {
	new id = GetNativeCell(1);
	decl String:strId[16];
	IntToString(id, strId, sizeof(strId));
	new junk;
	return GetTrieValue(g_id_cache, strId, junk);
	/*
	SQL_BindParamInt(g_statement_IsValidItemID, 0, id);
	SQL_Execute(g_statement_IsValidItemID);
	return SQL_GetRowCount(g_statement_IsValidItemID);
	*/
}

public Native_GetItemClass(Handle:hPlugin, nParams) {
	new id = GetNativeCell(1);
	new size = GetNativeCell(3);
	
	decl String:strId[16];
	IntToString(id, strId, sizeof(strId));
	decl String:class[size];

	if(GetTrieString(g_class_cache, strId, class, size)) {
		SetNativeString(2, class, size);
		return true;
	}
	return false;

	/*
	SQL_BindParamInt(g_statement_GetItemClass, 0, id);
	SQL_Execute(g_statement_GetItemClass);
	if(SQL_FetchRow(g_statement_GetItemClass)) {
		decl String:buffer[size];
		SQL_FetchString(g_statement_GetItemClass, 0, buffer, size);
		SetNativeString(2, buffer, size);
		return true;
	} else {
		return false;
	}
	*/
}

public Native_GetItemName(Handle:hPlugin, nParams) {
	new id = GetNativeCell(1);
	new size = GetNativeCell(3);
	SQL_BindParamInt(g_statement_GetItemName, 0, id);
	SQL_Execute(g_statement_GetItemName);
	if(SQL_FetchRow(g_statement_GetItemName)) {
		decl String:buffer[size];
		SQL_FetchString(g_statement_GetItemName, 0, buffer, size);
		SetNativeString(2, buffer, size);
		return true;
	} else {
		return false;
	}
}

public Native_GetItemSlotName(Handle:hPlugin, nParams) {
	new id = GetNativeCell(1);
	new size = GetNativeCell(3);
	
	decl String:strId[16];
	IntToString(id, strId, sizeof(strId));
	decl String:slot[size];

	if(GetTrieString(g_slot_cache, strId, slot, size)) {
		SetNativeString(2, slot, size);
		return true;
	}
	return false;

	/*
	SQL_BindParamInt(g_statement_GetItemSlotName, 0, id);
	SQL_Execute(g_statement_GetItemSlotName);
	if(SQL_FetchRow(g_statement_GetItemSlotName)) {
		decl String:buffer[size];
		SQL_FetchString(g_statement_GetItemSlotName, 0, buffer, size);
		SetNativeString(2, buffer, size);
		return true;
	} else {
		return false;
	}
	*/
}

public Native_GetItemSlot(Handle:hPlugin, nParams) {
	new id = GetNativeCell(1);
	decl String:slotString[16];
	if(TF2IDB_GetItemSlotName(id, slotString, sizeof(slotString))) {
		new TF2ItemSlot:slot;
		if(GetTrieValue(g_slot_mappings, slotString, slot)) {
			return _:slot;
		}
	}
	return _:0;
}

public Native_GetItemQualityName(Handle:hPlugin, nParams) {
	new id = GetNativeCell(1);
	new size = GetNativeCell(3);
	SQL_BindParamInt(g_statement_GetItemQualityName, 0, id);
	SQL_Execute(g_statement_GetItemQualityName);
	if(SQL_FetchRow(g_statement_GetItemQualityName)) {
		decl String:buffer[size];
		SQL_FetchString(g_statement_GetItemQualityName, 0, buffer, size);
		SetNativeString(2, buffer, size);
		return true;
	} else {
		return false;
	}
}

public Native_GetItemQuality(Handle:hPlugin, nParams) {
	new id = GetNativeCell(1);
	decl String:qualityString[16];
	if(TF2IDB_GetItemSlotName(id, qualityString, sizeof(qualityString))) {
		new TF2ItemQuality:quality;
		if(GetTrieValue(g_quality_mappings, qualityString, quality)) {
			return _:quality;
		}
	}
	return _:TF2ItemQuality_Normal;
}

public Native_GetItemLevels(Handle:hPlugin, nParams) {
	new id = GetNativeCell(1);
	decl String:strId[16];
	IntToString(id, strId, sizeof(strId));	
	new min,max;
	new bool:exists = GetTrieValue(g_minlevel_cache, strId, min);
	GetTrieValue(g_maxlevel_cache, strId, max);
	if(exists) {
		SetNativeCellRef(2, min);
		SetNativeCellRef(3, max);
	}
	return exists;

	/*
	SQL_BindParamInt(g_statement_GetItemLevels, 0, id);
	SQL_Execute(g_statement_GetItemLevels);
	if(SQL_FetchRow(g_statement_GetItemLevels)) {
		new min = SQL_FetchInt(g_statement_GetItemLevels, 0);
		new max = SQL_FetchInt(g_statement_GetItemLevels, 1);
		SetNativeCellRef(2, min);
		SetNativeCellRef(3, max);
		return true;
	} else {
		return false;
	}
	*/
}

public Native_GetItemAttributes(Handle:hPlugin, nParams) {
	new id = GetNativeCell(1);
	decl aids[TF2IDB_MAX_ATTRIBUTES];
	decl Float:values[TF2IDB_MAX_ATTRIBUTES];
	SQL_BindParamInt(g_statement_GetItemAttributes, 0, id);
	SQL_Execute(g_statement_GetItemAttributes);

	new index;
	while(SQL_FetchRow(g_statement_GetItemAttributes)) {
		new aid = SQL_FetchInt(g_statement_GetItemAttributes, 0);
		new Float:value = SQL_FetchFloat(g_statement_GetItemAttributes, 1);
		aids[index] = aid;
		values[index] = value;
		index++;
	}

	if(index) {
		SetNativeArray(2, aids, index);
		SetNativeArray(3, values, index);
	}

	return index;
}

public Native_GetItemEquipRegions(Handle:hPlugin, nParams) {
	new id = GetNativeCell(1);
	SQL_BindParamInt(g_statement_GetItemEquipRegions, 0, id);
	new Handle:list = CreateArray(ByteCountToCells(16));
	SQL_Execute(g_statement_GetItemEquipRegions);
	while(SQL_FetchRow(g_statement_GetItemEquipRegions)) {
		decl String:buffer[16];
		SQL_FetchString(g_statement_GetItemEquipRegions, 0, buffer, sizeof(buffer));
		PushArrayString(list, buffer);
	}
	new Handle:output = CloneHandle(list, hPlugin);
	CloseHandle(list);
	return _:output;
}

public Native_ListParticles(Handle:hPlugin, nParams) {
	new Handle:list = CreateArray();
	SQL_Execute(g_statement_ListParticles);
	while(SQL_FetchRow(g_statement_ListParticles)) {
		new effect = SQL_FetchInt(g_statement_ListParticles, 0);
		if(effect > 5 && effect < 2000 && effect != 20 && effect != 28)
			PushArrayCell(list, effect);
	}
	new Handle:output = CloneHandle(list, hPlugin);
	CloseHandle(list);
	return _:output;
}

public Native_DoRegionsConflict(Handle:hPlugin, nParams) {
	decl String:region1[16];
	decl String:region2[16];
	GetNativeString(1, region1, sizeof(region1));
	GetNativeString(2, region2, sizeof(region2));
	SQL_BindParamString(g_statement_DoRegionsConflict, 0, region1, false);
	SQL_BindParamString(g_statement_DoRegionsConflict, 1, region2, false);
	SQL_Execute(g_statement_DoRegionsConflict);
	return SQL_GetRowCount(g_statement_DoRegionsConflict) > 0;
}

public Native_FindItemCustom(Handle:hPlugin, nParams) {
	new length;
	GetNativeStringLength(1, length);
	decl String:query[length+1];
	GetNativeString(1, query, length+1);

	new Handle:queryHandle = SQL_Query(g_db, query);
	if(queryHandle == INVALID_HANDLE)
		return _:INVALID_HANDLE;
	new Handle:list = CreateArray();
	while(SQL_FetchRow(queryHandle)) {
		new id = SQL_FetchInt(queryHandle, 0);
		PushArrayCell(list, id);
	}
	CloseHandle(queryHandle);
	new Handle:output = CloneHandle(list, hPlugin);
	CloseHandle(list);
	return _:output;
}

public Native_ItemHasAttribute(Handle:hPlugin, nParams) {
	new id = GetNativeCell(1);
	new aid = GetNativeCell(2);

	SQL_BindParamInt(g_statement_ItemHasAttribute, 0, id);
	SQL_BindParamInt(g_statement_ItemHasAttribute, 1, aid);
	SQL_Execute(g_statement_ItemHasAttribute);

	if(SQL_FetchRow(g_statement_ItemHasAttribute)) {
		return SQL_GetRowCount(g_statement_ItemHasAttribute) > 0;
	}
	return false;
}