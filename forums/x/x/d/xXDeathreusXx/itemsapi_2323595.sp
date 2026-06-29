#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <socket>
#include <itemsapi> 

//#define DEBUG												// this will dump item parses to file

#define LOG_FILE_FPATH		"logs/itemsapidebug.log"		// path to write the usable items file to

#define API_FILE_TPATH		"data/itemsapi_temp.txt"		// path to write the incoming items file to
#define API_FILE_FPATH		"data/itemsapi.txt"				// path to write the usable items file to

#define KEY_MAX_LEN						33					// length of steam api key
#define URL_MAX_SIZE					256					// max size of steam API url + Key
#define ITEM_DEF_LEN					8					// max length of item definition index. Oh valve, why are robot hats over 4 digits?

#define ATTRIBUTE_DELIMITER_C			';'					// character to delimit name|value*name|value sets, should never exist in the schema file
#define ATTRIBUTE_DELIMITER_S			";"					// string version
#define ATTRIBUTE_PAIR_DELIMITER_C		'@'					// character to delimit name|value pairs, should never exist in the schema file
#define ATTRIBUTE_PAIR_DELIMITER_S		"@"					// string version
#define MAX_ATTRIBUTE_DELIM_LEN			1300				// max length of delimited pack of item attributes.. will probably never ever ever ever be this big
#define MAX_ATTRIBUTE_VALUE_LEN			16					// max length of an attribute float

#define PLUGIN_VERSION		"1.0.6"

new Handle:hCvarKey = INVALID_HANDLE;
new String:g_sKey[KEY_MAX_LEN];								// steam API Key to fetch schema, get yours here: http://steamcommunity.com/dev

new Handle:hCvarIval = INVALID_HANDLE;
new g_UpdateIval;											// time in seconds to refresh stale schema files

new bool:g_bSchema;											// do we have the schema file intact, even if it's stale?

new Handle:g_hItemSlotTrie = INVALID_HANDLE;				// item slots are stored here
new Handle:g_hItemItemclassTrie = INVALID_HANDLE;			// item classes are stored here
new Handle:g_hItemPaintTrie = INVALID_HANDLE;				// item paintability is stored here
new Handle:g_hItemNameTrie = INVALID_HANDLE;				// item names are stored here
new Handle:g_hItemCleanNameTrie = INVALID_HANDLE;			// items that have alternate 'clean' names are stored hear
new Handle:g_hItemAttributeTrie = INVALID_HANDLE;			// item attributes are stored here

public Plugin:myinfo =
{
	name = "[TF2] Items API Cache",
	author = "Friagram",
	description = "Stores Item Info",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/groups/poniponiponi"
};

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:sError[], iErrorSize)
{
	CreateNative("ItemsApi_Ready", Native_ItemsApi_Ready); 
	CreateNative("ItemsApi_GetSlot", Native_ItemsApi_GetSlot);
	CreateNative("ItemsApi_GetSlotEx", Native_ItemsApi_GetSlotEx);
	CreateNative("ItemsApi_Paintable", Native_ItemsApi_Paintable);
	CreateNative("ItemsApi_Wearable", Native_ItemsApi_Wearable);
	CreateNative("ItemsApi_GetClassName", Native_ItemsApi_GetClassName);	
	CreateNative("ItemsApi_GetName", Native_ItemsApi_GetName);
	CreateNative("ItemsApi_GetNumAttributes", Native_ItemsApi_GetNumAttributes);
	CreateNative("ItemsApi_GetAttribute", Native_ItemsApi_GetAttribute);

	RegPluginLibrary("itemsapi");

	return APLRes_Success;
}

public Native_ItemsApi_Ready(Handle:plugin,numParams)
{
	return g_bSchema;
}

public Native_ItemsApi_GetSlot(Handle:plugin,numParams)
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	new itemslot;														// if the item index is not located, we will return 0 (unknown)

	GetTrieValue(g_hItemSlotTrie, sindex, itemslot);

	if(GetNativeCell(2))												// return adjusted slots
	{
		decl String:itemclass[19];										// only needs to be big enough to process "tf_weapon_revolver"
		if(GetTrieString(g_hItemItemclassTrie, sindex, itemclass, 19) && StrEqual(itemclass, "tf_weapon_revolver"))
		{
			return _:TFia_Slot_primary;
		}
	}	
	
	return _:itemslot;
}

public Native_ItemsApi_GetSlotEx(Handle:plugin,numParams)
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	new TFiaSlotType:itemslot;											// if the item index is not located, we will return 0 (unknown)
	decl String:itemclass[19];											// only needs to be big enough to process "tf_weapon_revolver"

	GetTrieValue(g_hItemSlotTrie, sindex, itemslot);
	GetTrieString(g_hItemItemclassTrie, sindex, itemclass, 19);

	if(itemslot != TFia_Slot_head && itemslot != TFia_Slot_misc && StrEqual(itemclass, "tf_wearable"))
	{
		return _:GetNativeCell(2);										// filter out stuff that should not be wearables to provided category
	}
	
	if(GetNativeCell(3) && StrEqual(itemclass, "tf_weapon_revolver"))	// return adjusted slots
	{
		return _:TFia_Slot_primary;
	}

	return _:itemslot;
}

public Native_ItemsApi_Paintable(Handle:plugin,numParams)
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	new bool:paintable;													// the item may or may not exist in the trie (depending on if it has "capabilities")

	GetTrieValue(g_hItemPaintTrie, sindex, paintable);

	return paintable;
}

public Native_ItemsApi_Wearable(Handle:plugin,numParams)
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	decl String:itemclass[ITEM_CLASS_LEN];
		
	if(GetTrieString(g_hItemItemclassTrie, sindex, itemclass, ITEM_CLASS_LEN) && StrEqual(itemclass, "tf_wearable"))
	{
		return true;
	}

	return false;
}

public Native_ItemsApi_GetClassName(Handle:plugin, numParams)
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	decl String:itemclass[ITEM_CLASS_LEN];

	if(GetTrieString(g_hItemItemclassTrie, sindex, itemclass, ITEM_CLASS_LEN))
	{
		SetNativeString(2, itemclass, ITEM_CLASS_LEN, false);

		return strlen(itemclass);
	}

	return 0; 
}

public Native_ItemsApi_GetName(Handle:plugin, numParams)
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);	
	decl String:name[ITEM_NAME_LEN];
	
	if(GetNativeCell(3) && GetTrieString(g_hItemCleanNameTrie, sindex, name, ITEM_NAME_LEN))
	{
		SetNativeString(2, name, ITEM_NAME_LEN, false);

		return strlen(name);
	}
	
	if(GetTrieString(g_hItemNameTrie, sindex, name, ITEM_NAME_LEN))
	{
		SetNativeString(2, name, ITEM_NAME_LEN, false);

		return strlen(name);
	}

	return 0; 
}

public Native_ItemsApi_GetNumAttributes(Handle:plugin, numParams)
{
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	decl String:delimited[MAX_ATTRIBUTE_DELIM_LEN];

	if(GetTrieString(g_hItemAttributeTrie, sindex, delimited, MAX_ATTRIBUTE_DELIM_LEN))
	{
		new attcnt;														// number of attributes will always be equal to number of paired delimiters
		
		for(new i; delimited[i] != '\0'; i++)
		{
			if(delimited[i] == ATTRIBUTE_PAIR_DELIMITER_C)
			{
				attcnt++;
			}
		}
		
		return attcnt;
	}
	
	return 0;
}

public Native_ItemsApi_GetAttribute(Handle:plugin, numParams)
{   
	decl String:sindex[ITEM_DEF_LEN];
	IntToString(GetNativeCell(1), sindex, ITEM_DEF_LEN);
	decl String:delimited[MAX_ATTRIBUTE_DELIM_LEN];
	
	if(GetTrieString(g_hItemAttributeTrie, sindex, delimited, MAX_ATTRIBUTE_DELIM_LEN))
	{
		new targetatt = GetNativeCell(2);
		decl String:value[MAX_ATTRIBUTE_VALUE_LEN];
		decl String:name[MAX_ATTRIBUTE_NAME_LEN];
		new start;
		new attcnt;
	
		for(new i; delimited[i] != '\0'; i++)
		{
			if(delimited[i] == ATTRIBUTE_PAIR_DELIMITER_C)				// found a pair of attributes
			{        
				if(attcnt == targetatt)
				{
					strcopy(name, (i-start)+1, delimited[start]);		// copy the start position to the delimited position
					start = i+1;										// set the start position to the character after the delimited position
					
					while(delimited[i] != ATTRIBUTE_DELIMITER_C && delimited[i] != '\0')
					{
						i++;
					}
					strcopy(value, i-start, delimited[start]);
					
					SetNativeString(3, name, MAX_ATTRIBUTE_NAME_LEN, false);
					return _:StringToFloat(value); 
				}
				attcnt++;
			}
			else if(delimited[i] == ATTRIBUTE_DELIMITER_C)
			{
				start = i+1;
			}		
		}
	}
	return _:0.0;
}

public OnPluginStart()
{
	CreateConVar("itemsapi_version", PLUGIN_VERSION, "Items API Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookConVarChange(hCvarKey = CreateConVar("itemsapi_key", "", "Your Steam API Key. This is yours, do not share this.", FCVAR_PROTECTED), ConVarKeyChanged);
	HookConVarChange(hCvarIval = CreateConVar("itemsapi_ival", "0", "Minimum time to update the schema in minutes.", FCVAR_PLUGIN), ConVarIvalChanged);
	
	RegAdminCmd("sm_itemsapi_reload", Command_Reload, ADMFLAG_RCON, "Force manual update of the item schema");
	
	g_hItemSlotTrie = CreateTrie();
	g_hItemItemclassTrie = CreateTrie();
	g_hItemPaintTrie = CreateTrie();
	g_hItemNameTrie = CreateTrie();
	g_hItemCleanNameTrie = CreateTrie();
	g_hItemAttributeTrie = CreateTrie();
		
	g_bSchema = false;
}

public OnConfigsExecuted() 
{
	GetConVarString(hCvarKey, g_sKey, KEY_MAX_LEN);
	g_UpdateIval = GetConVarInt(hCvarIval) * 60;
	
	GetSchema(false);													// attempt to fetch fresh schema from the api if stale
}

public ConVarKeyChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	strcopy(g_sKey, KEY_MAX_LEN, newvalue);
}

public ConVarIvalChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_UpdateIval = StringToInt(newvalue) * 60;
}

public Action:Command_Reload(client, args)								// Socket stuff borrowed from McKay's SMDJ plugin :)
{							
	GetSchema(true);
	ReplyToCommand(client, "[SM] The item Schema will be refreshed.");
	
	return Plugin_Handled;
}

GetSchema(bool:update)
{
	decl String:path[PLATFORM_MAX_PATH];
	decl cachedtime;
		
	if(!update)
	{	
		BuildPath(Path_SM, path, PLATFORM_MAX_PATH, API_FILE_FPATH);
		cachedtime = GetFileTime(path, FileTime_LastChange);
		
		if(cachedtime == -1)
		{
			update = true;												// file doesn't exist
		}
		else if(g_UpdateIval)											// Let's check the final path first, to see if it's stale
		{
			if((cachedtime + g_UpdateIval) < GetTime())
			{
				update = true;
			}
		}
		else															// No time is set, synch with items_game
		{
			if(cachedtime < GetFileTime("scripts/items/items_game.txt", FileTime_LastChange))
			{
				update = true;
			}
		}
	}
	
	if(update)										// do an update it forced or file is stale
	{
		new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
		decl String:url[URL_MAX_SIZE];
		BuildPath(Path_SM, path, PLATFORM_MAX_PATH, API_FILE_TPATH);	// Create a file at the temporary path

		new Handle:pack = CreateDataPack();
		new Handle:file = OpenFile(path, "wb");
	
		WritePackCell(pack, _:file);
		Format(url, URL_MAX_SIZE, "GET /IEconItems_440/GetSchema/v0001/?key=%s&format=vdf HTTP/1.0\r\nHost: api.steampowered.com\r\nConnection: close\r\nPragma: no-cache\r\nCache-Control: no-cache\r\n\r\n", g_sKey);
	
		WritePackString(pack, url);
	
		SocketSetArg(socket, pack);
		SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "api.steampowered.com", 80);
	}
	else
	{
		PrintToServer("[ItemsApi]: Item schema is fresh (%.2f hours old).",(GetTime()-cachedtime)/3600.0);
		PopulateItemTrie();												// categorieze teh loot
	}
}

public OnSocketConnected(Handle:socket, any:pack)
{
	ResetPack(pack);
	decl String:url[URL_MAX_SIZE];
	ReadPackCell(pack); // iterate the pack over the file
	ReadPackString(pack, url, URL_MAX_SIZE);
	
	SocketSend(socket, url);
}

public OnSocketReceive(Handle:socket, String:data[], const size, any:pack)
{
	ResetPack(pack);
	new Handle:file = Handle:ReadPackCell(pack);
	
	// Skip the header data.
	new pos = StrContains(data, "\r\n\r\n");
	pos = (pos != -1) ? pos + 4 : 0;
	
	for (new i = pos; i < size; i++) {
		WriteFileCell(file, data[i], 1);
	}
}

public OnSocketDisconnected(Handle:socket, any:pack)
{
	ResetPack(pack);
	CloseHandle(Handle:ReadPackCell(pack));
	CloseHandle(pack);
	CloseHandle(socket);
	
	decl String:tempfile[PLATFORM_MAX_PATH], String:line[10];
	BuildPath(Path_SM, tempfile, PLATFORM_MAX_PATH, API_FILE_TPATH);		// this is the newly downloaded file
	
	new Handle:file = OpenFile(tempfile, "r");
	ReadFileLine(file, line, sizeof(line));
	CloseHandle(file); 

	decl String:cachedfile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, cachedfile, PLATFORM_MAX_PATH, API_FILE_FPATH);		// this is the potentially older cached file	
	
	if(StrContains(line, "result") == -1)
	{
		if(StrContains(line, "<html>") != -1)
		{
			LogError("Failed to fetch fresh item schema, invalid API Key?");
		}
		else
		{
			LogError("Failed to fetch fresh item schema");
		}

		if(FileExists(cachedfile))
		{
			PopulateItemTrie();												// use the fallback file
			PrintToServer("[ItemsApi]: Falling back to cached item schema.");
		}
	
		return;
	}
	
	if(FileExists(cachedfile))
	{
		DeleteFile(cachedfile);												// remove the old schema file, if it exists
	}
	RenameFile(cachedfile, tempfile);										// rename the newly created schema
	
	PopulateItemTrie();														// categorieze teh loot
	PrintToServer("[ItemsApi]: Item schema updated.");
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:pack)
{
	ResetPack(pack);
	CloseHandle(Handle:ReadPackCell(pack));
	CloseHandle(pack);
	CloseHandle(socket);

	decl String:error[256];
	FormatEx(error, sizeof(error), "Socket error: %d (Error code %d)", errorType, errorNum);
}

public Handle:PopulateItemTrie()
{
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, API_FILE_FPATH);
	
	new Handle:hKvItems = CreateKeyValues("itemsapi");

	if (!FileToKeyValues(hKvItems, path))
	{
		LogError("Could not open the item schema, even though it should be there!");
		
		g_bSchema = false;
		return;
	}

	ClearTrie(g_hItemSlotTrie);
	ClearTrie(g_hItemItemclassTrie);
	ClearTrie(g_hItemPaintTrie);
	ClearTrie(g_hItemNameTrie);
	ClearTrie(g_hItemCleanNameTrie);
	ClearTrie(g_hItemAttributeTrie);
	
	decl String:name[ITEM_NAME_LEN];
	decl String:cleanname[ITEM_NAME_LEN];
	decl String:slot[10];
	decl defindex;
	decl String:sindex[ITEM_DEF_LEN];
	decl String:itemclass[ITEM_CLASS_LEN];
	decl tolower;
	decl String:delimitedattributes[MAX_ATTRIBUTE_DELIM_LEN];
	decl String:attributename[MAX_ATTRIBUTE_NAME_LEN];
	decl String:attributevalue[MAX_ATTRIBUTE_VALUE_LEN];
	decl bool:deliminate;
	
	KvRewind(hKvItems);
	if(KvJumpToKey(hKvItems, "items"))														// it begins
	{
		KvGotoFirstSubKey(hKvItems, false);
		do
		{
			defindex = KvGetNum(hKvItems, "defindex", -1);
			if(defindex != -1)																// it's a valid-ish item
			{
				IntToString(defindex, sindex, ITEM_DEF_LEN);
				KvGetString(hKvItems, "item_slot", slot, 10, "");
				KvGetString(hKvItems, "name", name, ITEM_NAME_LEN, "UNKNOWN_TF_ITEM");		// this 'should' never happen
				KvGetString(hKvItems, "item_class", itemclass, ITEM_CLASS_LEN, "");
								
				if(StrEqual(slot, "head"))													// throw items into slot types
				{
					SetTrieValue(g_hItemSlotTrie, sindex, TFia_Slot_head);	
				}
				else if(StrEqual(slot, "misc"))
				{
					SetTrieValue(g_hItemSlotTrie, sindex, TFia_Slot_misc);	
				}
				else if(StrEqual(slot, "action"))
				{
					SetTrieValue(g_hItemSlotTrie, sindex, TFia_Slot_action);	
				}
				else if(StrEqual(slot, "primary"))
				{
					SetTrieValue(g_hItemSlotTrie, sindex, TFia_Slot_primary);									
				}
				else if(StrEqual(slot, "secondary"))
				{
					SetTrieValue(g_hItemSlotTrie, sindex, TFia_Slot_secondary);	
				}
				else if(StrEqual(slot, "melee"))
				{
					SetTrieValue(g_hItemSlotTrie, sindex, TFia_Slot_melee);	
				}
				else if(StrEqual(slot, "building"))
				{
					SetTrieValue(g_hItemSlotTrie, sindex, TFia_Slot_building);	
				}
				else if(StrEqual(slot, "pda"))
				{
					SetTrieValue(g_hItemSlotTrie, sindex, TFia_Slot_pda);	
				}
				else if(StrEqual(slot, "pda2"))
				{
					SetTrieValue(g_hItemSlotTrie, sindex, TFia_Slot_pda2);	
				}
				
				if((tolower = StrContains(name, "TF_WEAPON_")) != -1)						// This will clean up the names for display.... There's not many like this
				{
					strcopy(cleanname, ITEM_NAME_LEN, name);
					tolower += 11;															// I want the first letter to be Caps
					while( cleanname[tolower] != '\0')
					{																		// Just parse between delimiter
						cleanname[tolower] = CharToLower(cleanname[tolower]);
						tolower++;
					}
					
					// Prefix (caps)
					ReplaceString(cleanname, ITEM_NAME_LEN, "TF_WEAPON_", "");
					ReplaceString(cleanname, ITEM_NAME_LEN, "Upgradeable ", "");
					
					// Suffix (lower)
					if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_hwg", ""))								// and... weeee
						if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_soldier", ""))
							if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_pyro", ""))
								if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_medic", ""))
									if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_scout", ""))
										if(!ReplaceString(cleanname, ITEM_NAME_LEN, "_spy", ""))
											ReplaceString(cleanname, ITEM_NAME_LEN, "_engineer", "");		// Will still say Pda build or Pda destroy
					
					ReplaceString(cleanname, ITEM_NAME_LEN, "_primary", "");			
					ReplaceString(cleanname, ITEM_NAME_LEN, "_", " ");						// is this still needed?
					
					SetTrieString(g_hItemCleanNameTrie, sindex, cleanname);					// store the alternative name
				}
				
				SetTrieString(g_hItemNameTrie, sindex, name);
				SetTrieString(g_hItemItemclassTrie, sindex, itemclass);
				
				if(KvJumpToKey(hKvItems, "capabilities"))									// test if paint cans can be applied
				{
					SetTrieValue(g_hItemPaintTrie, sindex, KvGetNum(hKvItems, "paintable", 0));
					KvGoBack(hKvItems);
				}
				
				if(KvJumpToKey(hKvItems, "attributes"))									// prepare attributes
				{
					delimitedattributes[0] = '\0';										// reset the buffer
					deliminate = false;													// don't deliminate the first item
					
					if(KvGotoFirstSubKey(hKvItems, false))								// some have attributes but are empty
					{
						do
						{
							KvGetString(hKvItems, "name", attributename, MAX_ATTRIBUTE_NAME_LEN);
							KvGetString(hKvItems, "value", attributevalue, MAX_ATTRIBUTE_VALUE_LEN);						
							
							if(!deliminate)
							{
								deliminate = true;	
							}
							else
							{
								StrCat(delimitedattributes, MAX_ATTRIBUTE_DELIM_LEN, ATTRIBUTE_DELIMITER_S);
							}
							StrCat(delimitedattributes, MAX_ATTRIBUTE_DELIM_LEN, attributename);
							StrCat(delimitedattributes, MAX_ATTRIBUTE_DELIM_LEN, ATTRIBUTE_PAIR_DELIMITER_S);
							StrCat(delimitedattributes, MAX_ATTRIBUTE_DELIM_LEN, attributevalue);					
				
				
							SetTrieString(g_hItemAttributeTrie, sindex, delimitedattributes);
						}
						while(KvGotoNextKey(hKvItems, false));
					
						KvGoBack(hKvItems);
					}
					
					KvGoBack(hKvItems);
				}				
				
#if defined DEBUG				
				decl String:logpath[PLATFORM_MAX_PATH];										// dump most everything to file incase there's some issues. Sloppy sloppy sloppy
				BuildPath(Path_SM, logpath, PLATFORM_MAX_PATH, LOG_FILE_FPATH);
				
				decl tempindex;
				GetTrieValue(g_hItemSlotTrie, sindex, tempindex);
				
				decl String:tempname[ITEM_NAME_LEN];
				GetTrieString(g_hItemNameTrie, sindex, tempname, ITEM_NAME_LEN);
				
				new tempwearable;															// may not exist
				new tempwearableexists = GetTrieValue(g_hItemWearableTrie, sindex, tempwearable);
				
				decl temppaint;
				GetTrieValue(g_hItemPaintTrie, sindex, temppaint);
				
				new String:tempattribs[MAX_ATTRIBUTE_DELIM_LEN]; 							// may not exist
				new tempattribsexists = GetTrieString(g_hItemAttributeTrie, sindex, tempattribs, MAX_ATTRIBUTE_DELIM_LEN);
									
				LogToFile(logpath, "[defidx:%d] [name:%s] [slot:%d] [wearable:%d-%d] [paint:%d] [attribs:%d] %s", defindex, tempname, tempindex, tempwearableexists, tempwearable, temppaint, tempattribsexists, tempattribs);
#endif				
			}		
		}
		while (KvGotoNextKey(hKvItems, false));
	}
	
	CloseHandle(hKvItems);

	g_bSchema = true;
}