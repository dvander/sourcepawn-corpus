#pragma semicolon 1

#include <sourcemod>
#include <store>
#include <scp>
#include <smjansson>
#include <csgocolors>



enum Title
{
	String:TitleName[STORE_MAX_NAME_LENGTH],
	String:TitleText[64]
}
enum NameColor
{
	String:NameColorName[STORE_MAX_NAME_LENGTH],
	String:NameColorText[64]
}

new g_titles[1024][Title];
new g_namecolors[1024][NameColor];

new g_titleCount = 0;
new g_namecolorCount = 0;

new g_clientTitles[MAXPLAYERS+1] = { -1, ... };
new g_clientNameColors[MAXPLAYERS+1] = { -1, ... };

new Handle:g_titlesNameIndex = INVALID_HANDLE;
new Handle:g_namecolorsNameIndex = INVALID_HANDLE;

new bool:g_databaseInitialized = false;

public Plugin:myinfo =
{
	name        = "[Store] Chat",
	author      = "Panduh",
	description = "A combination of Titles and Title Colors for [Store]",
	version     = "1.2.0",
	url         = "http://forums.alliedmodders.com/"
};

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("store.phrases");

	Store_RegisterItemType("title", OnTitleLoad, OnTitleLoadItem);
	Store_RegisterItemType("namecolor", OnNameEquip, OnLoadNameItem);
	Store_RegisterPluginModule("[Store] Chat Titles and Colors", "Chat Titles and Colors component for [Store]", "sm_chat_version", "1.2");
}

/** 
 * Called when a new API library is loaded.
 */
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "store-inventory"))
	{
		Store_RegisterItemType("title", OnTitleLoad, OnTitleLoadItem);
		Store_RegisterItemType("namecolor", OnNameEquip, OnLoadNameItem);
	}	
}

public Store_OnDatabaseInitialized()
{
	g_databaseInitialized = true;
}

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientPostAdminCheck(client)
{
	if (!g_databaseInitialized)
		return;

	g_clientTitles[client] = -1;
	g_clientNameColors[client] = -1;

		
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "title", Store_GetClientLoadout(client), OnGetPlayerTitle, GetClientSerial(client));
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "namecolor", Store_GetClientLoadout(client), OnGetPlayerNameColor, GetClientSerial(client));
}

public Store_OnClientLoadoutChanged(client)
{
	g_clientTitles[client] = -1;
	g_clientNameColors[client] = -1;
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "title", Store_GetClientLoadout(client), OnGetPlayerTitle, GetClientSerial(client));
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "namecolor", Store_GetClientLoadout(client), OnGetPlayerNameColor, GetClientSerial(client));
}

public Store_OnReloadItems() 
{
	if (g_titlesNameIndex != INVALID_HANDLE)
		CloseHandle(g_titlesNameIndex);
	
	g_titlesNameIndex = CreateTrie();
	g_titleCount = 0;
	
	if (g_namecolorsNameIndex != INVALID_HANDLE)
		CloseHandle(g_namecolorsNameIndex);
		
	g_namecolorsNameIndex = CreateTrie();
	g_namecolorCount = 0;	
}

public OnGetPlayerTitle(titles[], count, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
		return;
		
	for (new index = 0; index < count; index++)
	{
		decl String:itemName[STORE_MAX_NAME_LENGTH];
		Store_GetItemName(titles[index], itemName, sizeof(itemName));
		
		new title = -1;
		if (!GetTrieValue(g_titlesNameIndex, itemName, title))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			continue;
		}
		
		g_clientTitles[client] = title;
		break;
	}
}

public OnGetPlayerNameColor(titles[], count, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
		return;
		
	for (new index = 0; index < count; index++)
	{
		decl String:itemName[STORE_MAX_NAME_LENGTH];
		Store_GetItemName(titles[index], itemName, sizeof(itemName));
		
		new namecolor = -1;
		if (!GetTrieValue(g_namecolorsNameIndex, itemName, namecolor))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			continue;
		}
		
		g_clientNameColors[client] = namecolor;
		break;
	}
}

public OnTitleLoadItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_titles[g_titleCount][TitleName], STORE_MAX_NAME_LENGTH, itemName);
		
	SetTrieValue(g_titlesNameIndex, g_titles[g_titleCount][TitleName], g_titleCount);
	
	new Handle:json = json_load(attrs);	
	json_object_get_string(json, "text", g_titles[g_titleCount][TitleText], 64);

	CloseHandle(json);

	g_titleCount++;
}

public OnLoadNameItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_namecolors[g_namecolorCount][NameColorName], STORE_MAX_NAME_LENGTH, itemName);
		
	SetTrieValue(g_namecolorsNameIndex, g_namecolors[g_namecolorCount][NameColorName], g_namecolorCount);
	
	new Handle:json = json_load(attrs);	
	json_object_get_string(json, "text", g_namecolors[g_namecolorCount][NameColorText], 64);
	CFormat(g_namecolors[g_namecolorCount][NameColorText], 64);

	CloseHandle(json);

	g_namecolorCount++;
}

public Store_ItemUseAction:OnTitleLoad(client, itemId, bool:equipped)
{
	new String:name[32];
	Store_GetItemName(itemId, name, sizeof(name));

	if (equipped)
	{
		g_clientTitles[client] = -1;
		
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Unequipped item", displayName);

		return Store_UnequipItem;
	}
	else
	{
		new title = -1;
		if (!GetTrieValue(g_titlesNameIndex, name, title))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			return Store_DoNothing;
		}
		
		g_clientTitles[client] = title;
		
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item", displayName);

		return Store_EquipItem;
	}
}

public Store_ItemUseAction:OnNameEquip(client, itemId, bool:equipped)
{
	new String:name[32];
	Store_GetItemName(itemId, name, sizeof(name));

	if (equipped)
	{
		g_clientNameColors[client] = -1;
		
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Unequipped item", displayName);

		return Store_UnequipItem;
	}
	else
	{
		new namecolor = -1;
		if (!GetTrieValue(g_namecolorsNameIndex, name, namecolor))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			return Store_DoNothing;
		}
		
		g_clientNameColors[client] = namecolor;
		
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item", displayName);

		return Store_EquipItem;
	}
}

public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
	new bool:bChanged;
	decl String:sTitle[64];
	if (g_clientTitles[author] != -1)
	{
		bChanged = true;
		Format(sTitle, sizeof(sTitle), "%s \x03", g_titles[g_clientTitles[author]][TitleText]);		
	}
	else
		strcopy(sTitle, sizeof(sTitle), "");

	if (g_clientNameColors[author] != -1)
	{
			bChanged = true;
			Format(name, MAXLENGTH_NAME, "%s%s\x03%s", g_namecolors[g_clientNameColors[author]][NameColorText], sTitle, name);
	}	
	
	else if (g_clientTitles[author] != -1)
	{
		bChanged = true;
		Format(name, MAXLENGTH_NAME, "%s\x03%s", sTitle, name);
	}
	

	if(bChanged)
		return Plugin_Changed;
	
	return Plugin_Continue;
}
