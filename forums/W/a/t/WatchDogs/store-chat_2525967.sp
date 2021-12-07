#pragma semicolon 1

#include <sourcemod>
#include <store>
#include <scp>
#include <smjansson>
#include <colors>
#include <morecolors_store>

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
enum ChatColor
{
	String:ChatColorName[STORE_MAX_NAME_LENGTH],
	String:ChatColorText[64]
}

new g_titles[1024][Title];
new g_namecolors[1024][NameColor];
new g_chatcolors[1024][ChatColor];

new g_titleCount = 0;
new g_namecolorCount = 0;
new g_chatcolorCount = 0;

new g_clientTitles[MAXPLAYERS + 1] = { -1, ... };
new g_clientNameColors[MAXPLAYERS+1] = { -1, ... };
new g_clientChatColors[MAXPLAYERS+1] = { -1, ... };

new Handle:g_titlesNameIndex = INVALID_HANDLE;
new Handle:g_namecolorsNameIndex = INVALID_HANDLE;
new Handle:g_chatcolorsNameIndex = INVALID_HANDLE;

new bool:g_databaseInitialized = false;

public Plugin:myinfo =
{
	name        = "[Store] Chat",
	author      = "Panduh",
	description = "A combination of Titles, Name Colors, and Chat Colors for [Store]",
	version     = "1.1.0",
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
	Store_RegisterItemType("chatcolor", OnChatEquip, OnLoadChatItem);
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
		Store_RegisterItemType("chatcolor", OnChatEquip, OnLoadChatItem);
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
	g_clientChatColors[client] = -1;

	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "title", Store_GetClientCurrentLoadout(client), OnGetPlayerTitle, GetClientSerial(client));
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "namecolor", Store_GetClientCurrentLoadout(client), OnGetPlayerNameColor, GetClientSerial(client));
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "chatcolor", Store_GetClientCurrentLoadout(client), OnGetPlayerChatColor, GetClientSerial(client));
}

public Store_OnClientLoadoutChanged(client)
{
	g_clientTitles[client] = -1;
	g_clientNameColors[client] = -1;
	g_clientChatColors[client] = -1;
	
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "title", Store_GetClientCurrentLoadout(client), OnGetPlayerTitle, GetClientSerial(client));
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "namecolor", Store_GetClientCurrentLoadout(client), OnGetPlayerNameColor, GetClientSerial(client));
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "chatcolor", Store_GetClientCurrentLoadout(client), OnGetPlayerChatColor, GetClientSerial(client));
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
	
	if (g_chatcolorsNameIndex != INVALID_HANDLE)
		CloseHandle(g_chatcolorsNameIndex);
		
	g_chatcolorsNameIndex = CreateTrie();
	g_chatcolorCount = 0;
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

public OnGetPlayerChatColor(titles[], count, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
		return;
		
	for (new index = 0; index < count; index++)
	{
		decl String:itemName[STORE_MAX_NAME_LENGTH];
		Store_GetItemName(titles[index], itemName, sizeof(itemName));
		
		new chatcolor = -1;
		if (!GetTrieValue(g_chatcolorsNameIndex, itemName, chatcolor))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			continue;
		}
		
		g_clientChatColors[client] = chatcolor;
		break;
	}
}

public OnTitleLoadItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_titles[g_titleCount][TitleName], STORE_MAX_NAME_LENGTH, itemName);
		
	SetTrieValue(g_titlesNameIndex, g_titles[g_titleCount][TitleName], g_titleCount);
	
	new Handle:json = json_load(attrs);	

	if (IsSource2009())
	{
		json_object_get_string(json, "colorful_text", g_titles[g_titleCount][TitleText], 64);
		MoreColors_CReplaceColorCodes(g_titles[g_titleCount][TitleText]);
	}
	else
	{
		json_object_get_string(json, "text", g_titles[g_titleCount][TitleText], 64);
		CFormat(g_titles[g_titleCount][TitleText], 64);
	}

	CloseHandle(json);

	g_titleCount++;
}

public OnLoadNameItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_namecolors[g_namecolorCount][NameColorName], STORE_MAX_NAME_LENGTH, itemName);
		
	SetTrieValue(g_namecolorsNameIndex, g_namecolors[g_namecolorCount][NameColorName], g_namecolorCount);
	
	new Handle:json = json_load(attrs);	
	
	if (IsSource2009())
	{
		json_object_get_string(json, "color", g_namecolors[g_namecolorCount][NameColorText], 64);
		MoreColors_CReplaceColorCodes(g_namecolors[g_namecolorCount][NameColorText]);
	}
	else
	{
		json_object_get_string(json, "text", g_namecolors[g_namecolorCount][NameColorText], 64);
		CFormat(g_namecolors[g_namecolorCount][NameColorText], 64);
	}

	CloseHandle(json);

	g_namecolorCount++;
}

public OnLoadChatItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_chatcolors[g_chatcolorCount][ChatColorName], STORE_MAX_NAME_LENGTH, itemName);
		
	SetTrieValue(g_chatcolorsNameIndex, g_chatcolors[g_chatcolorCount][ChatColorName], g_chatcolorCount);
	
	new Handle:json = json_load(attrs);	
	
	if (IsSource2009())
	{
		json_object_get_string(json, "color", g_chatcolors[g_chatcolorCount][ChatColorText], 64);
		MoreColors_CReplaceColorCodes(g_chatcolors[g_chatcolorCount][ChatColorText]);
	}
	else
	{
		json_object_get_string(json, "text", g_namecolors[g_chatcolorCount][ChatColorText], 64);
		CFormat(g_chatcolors[g_chatcolorCount][ChatColorText], 64);
	}

	CloseHandle(json);

	g_chatcolorCount++;
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

public Store_ItemUseAction:OnChatEquip(client, itemId, bool:equipped)
{
	new String:name[32];
	Store_GetItemName(itemId, name, sizeof(name));

	if (equipped)
	{
		g_clientChatColors[client] = -1;
		
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Unequipped item", displayName);

		return Store_UnequipItem;
	}
	else
	{
		new chatcolor = -1;
		if (!GetTrieValue(g_chatcolorsNameIndex, name, chatcolor))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			return Store_DoNothing;
		}
		
		g_clientChatColors[client] = chatcolor;
		
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
		if(strlen(g_namecolors[g_clientNameColors[author]][NameColorText]) == 6)
		{
			bChanged = true;
			Format(name, MAXLENGTH_NAME, "%s\x07%s%s", sTitle, g_namecolors[g_clientNameColors[author]][NameColorText], name);
		}	
		else if(strlen(g_namecolors[g_clientNameColors[author]][NameColorText]) == 8)
		{
			bChanged = true;
			Format(name, MAXLENGTH_NAME, "%s\x08%s%s", sTitle, g_namecolors[g_clientNameColors[author]][NameColorText], name);
		}		
	}
	else if (g_clientTitles[author] != -1)
	{
		bChanged = true;
		Format(name, MAXLENGTH_NAME, "%s%s", sTitle, name);
	}
	
	if (g_clientChatColors[author] != -1)
	{
		new iMax = MAXLENGTH_MESSAGE - strlen(name) - 5;

		if(strlen(g_chatcolors[g_clientChatColors[author]][ChatColorText]) == 6)
		{
			bChanged = true;
			Format(message, iMax, "\x07%s%s", g_chatcolors[g_clientChatColors[author]][ChatColorText], message);
		}
		else if(strlen(g_chatcolors[g_clientChatColors[author]][ChatColorText]) == 8)
		{
			bChanged = true;
			Format(message, iMax, "\x08%s%s", g_chatcolors[g_clientChatColors[author]][ChatColorText], message);
		}
	}

	if(bChanged)
		return Plugin_Changed;
	
	return Plugin_Continue;
}

stock bool:IsSource2009()
{
	return (SOURCE_SDK_CSS <= GuessSDKVersion() < SOURCE_SDK_LEFT4DEAD);
}