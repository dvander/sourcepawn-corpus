#pragma semicolon 1

//Includes
#include <sourcemod>
#include <store>

//Defines
#define PLUGIN_NAME "[Store] Backend Module"
#define PLUGIN_DESCRIPTION "Backend module for the Sourcemod Store."
#define PLUGIN_VERSION_CONVAR "store_backend_version"

//Query Strings
char sQuery_Register[] = "INSERT INTO store_users (auth, name, credits) VALUES (%d, '%s', %d) ON DUPLICATE KEY UPDATE name = '%s';";
char sQuery_GetClientUserID[] = "SELECT user_id FROM store_users WHERE auth = %d;";
char sQuery_GetCategories[] = "SELECT id, priority, display_name, description, require_plugin, enable_server_restriction FROM store_categories %s;";
char sQuery_GetItems[] = "SELECT id, priority, name, display_name, description, type, loadout_slot, price, category_id, attrs, LENGTH(attrs) AS attrs_len, is_buyable, is_tradeable, is_refundable, flags, enable_server_restriction FROM store_items ORDER BY price, display_name %s;";
char sQuery_GetItemAttributes[] = "SELECT attrs, LENGTH(attrs) AS attrs_len FROM store_items WHERE name = '%s';";
char sQuery_WriteItemAttributes[] = "UPDATE store_items SET attrs = '%s}' WHERE name = '%s';";
char sQuery_GetLoadouts[] = "SELECT id, display_name, game, class, team FROM store_loadouts;";
char sQuery_GetClientLoadouts[] = "SELECT category_id FROM `store_user_loadouts` WHERE auth = '%d';";
char sQuery_GetUserItems[] = "SELECT item_id, EXISTS(SELECT * FROM store_users_items_loadouts WHERE store_users_items_loadouts.useritem_id = store_users_items.id AND store_users_items_loadouts.loadout_id = %d) AS equipped, COUNT(*) AS count FROM store_users_items INNER JOIN store_users ON store_users.id = store_users_items.user_id INNER JOIN store_items ON store_items.id = store_users_items.item_id WHERE store_users.auth = %d AND ((store_users_items.acquire_date IS NULL OR store_items.expiry_time IS NULL OR store_items.expiry_time = 0) OR (store_users_items.acquire_date IS NOT NULL AND store_items.expiry_time IS NOT NULL AND store_items.expiry_time <> 0 AND DATE_ADD(store_users_items.acquire_date, INTERVAL store_items.expiry_time SECOND) > NOW()))";
char sQuery_GetUserItems_categoryId[] = "%s AND store_items.category_id = %d";
char sQuery_GetUserItems_isBuyable[] = "%s AND store_items.is_buyable = %b";
char sQuery_GetUserItems_isTradeable[] = "%s AND store_items.is_tradeable = %b";
char sQuery_GetUserItems_isRefundable[] = "%s AND store_items.is_refundable = %b";
char sQuery_GetUserItems_type[] = "%s AND store_items.type = '%s'";
char sQuery_GetUserItems_GroupByID[] = "%s GROUP BY item_id;";
char sQuery_GetUserItemsCount[] = "SELECT COUNT(*) AS count FROM store_users_items INNER JOIN store_users ON store_users.id = store_users_items.user_id INNER JOIN store_items ON store_items.id = store_users_items.item_id WHERE store_items.name = '%s' AND store_users.auth = %d;";
char sQuery_GetCredits[] = "SELECT credits FROM store_users WHERE auth = %d;";
char sQuery_RemoveUserItem[] = "DELETE FROM store_users_items WHERE store_users_items.item_id = %d AND store_users_items.user_id IN (SELECT store_users.id FROM store_users WHERE store_users.auth = %d) LIMIT 1;";
char sQuery_EquipUnequipItem[] = "INSERT INTO store_users_items_loadouts (loadout_id, useritem_id) SELECT %d AS loadout_id, store_users_items.id FROM store_users_items INNER JOIN store_users ON store_users.id = store_users_items.user_id WHERE store_users.auth = %d AND store_users_items.item_id = %d LIMIT 1;";
char sQuery_UnequipItem[] = "DELETE store_users_items_loadouts FROM store_users_items_loadouts INNER JOIN store_users_items ON store_users_items.id = store_users_items_loadouts.useritem_id INNER JOIN store_users ON store_users.id = store_users_items.user_id INNER JOIN store_items ON store_items.id = store_users_items.item_id WHERE store_users.auth = %d AND store_items.loadout_slot = (SELECT loadout_slot from store_items WHERE store_items.id = %d)";
char sQuery_UnequipItem_loadoutId[] = "%s AND store_users_items_loadouts.loadout_id = %d;";
char sQuery_GetEquippedItemsByType[] = "SELECT store_items.id FROM store_users_items INNER JOIN store_items ON store_items.id = store_users_items.item_id INNER JOIN store_users ON store_users.id = store_users_items.user_id INNER JOIN store_users_items_loadouts ON store_users_items_loadouts.useritem_id = store_users_items.id WHERE store_users.auth = %d AND store_items.type = '%s' AND store_users_items_loadouts.loadout_id = %d;";
char sQuery_GiveCredits[] = "UPDATE store_users SET credits = credits + %d WHERE auth = %d;";
char sQuery_RemoveCredits_Negative[] = "UPDATE store_users SET credits = 0 WHERE auth = %d;";
char sQuery_RemoveCredits[] = "UPDATE store_users SET credits = credits - %d WHERE auth = %d;";
char sQuery_GiveItem[] = "INSERT INTO store_users_items (user_id, item_id, acquire_date, acquire_method) SELECT store_users.id AS userId, '%d' AS item_id, NOW() as acquire_date, ";
char sQuery_GiveItem_Shop[] = "%s'shop'";
char sQuery_GiveItem_Trade[] = "%s'trade'";
char sQuery_GiveItem_Gift[] = "%s'gift'";
char sQuery_GiveItem_Admin[] = "%s'admin'";
char sQuery_GiveItem_Web[] = "%s'web'";
char sQuery_GiveItem_Unknown[] = "%sNULL";
char sQuery_GiveItem_End[] = "%s AS acquire_method FROM store_users WHERE auth = %d;";
char sQuery_GiveCreditsToUsers[] = "UPDATE store_users SET credits = credits + %d WHERE auth IN (";
char sQuery_GiveCreditsToUsers_End[] = "%s);";
char sQuery_RemoveCreditsFromUsers[] = "UPDATE store_users SET credits = credits - %d WHERE auth IN (";
char sQuery_RemoveCreditsFromUsers_End[] = "%s);";
char sQuery_GiveDifferentCreditsToUsers[] = "UPDATE store_users SET credits = credits + CASE auth";
char sQuery_GiveDifferentCreditsToUsers_accountIdsLength[] = "%s WHEN %d THEN %d";
char sQuery_GiveDifferentCreditsToUsers_End[] = "%s END WHERE auth IN (";
char sQuery_RemoveDifferentCreditsFromUsers[] = "UPDATE store_users SET credits = credits - CASE auth";
char sQuery_RemoveDifferentCreditsFromUsers_accountIdsLength[] = "%s WHEN %d THEN %d";
char sQuery_RemoveDifferentCreditsFromUsers_End[] = "%s END WHERE auth IN (";
char sQuery_GetCreditsEx[] = "SELECT credits FROM store_users WHERE auth = %d;";
char sQuery_RegisterPluginModule[] = "INSERT INTO store_versions (mod_name, mod_description, mod_ver_convar, mod_ver_number, server_id, last_updated) VALUES ('%s', '%s', '%s', '%s', '%d', NOW()) ON DUPLICATE KEY UPDATE mod_name = VALUES(mod_name), mod_description = VALUES(mod_description), mod_ver_convar = VALUES(mod_ver_convar), mod_ver_number = VALUES(mod_ver_number), server_id = VALUES(server_id), last_updated = NOW();";
char sQuery_CacheRestrictionsCategories[] = "SELECT category_id, server_id FROM store_servers_categories;";
char sQuery_CacheRestrictionsItems[] = "SELECT item_id, server_id FROM store_servers_items;";

//Categories
enum Category
{
	CategoryId,
	CategoryPriority,
	String:CategoryDisplayName[STORE_MAX_DISPLAY_NAME_LENGTH],
	String:CategoryDescription[STORE_MAX_DESCRIPTION_LENGTH],
	String:CategoryRequirePlugin[STORE_MAX_REQUIREPLUGIN_LENGTH],
	bool:CategoryDisableServerRestriction
}

int g_categories[MAX_CATEGORIES][Category];
int g_categoryCount = -1;

//Items
enum Item
{
	ItemId,
	ItemPriority,
	String:ItemName[STORE_MAX_NAME_LENGTH],
	String:ItemDisplayName[STORE_MAX_DISPLAY_NAME_LENGTH],
	String:ItemDescription[STORE_MAX_DESCRIPTION_LENGTH],
	String:ItemType[STORE_MAX_TYPE_LENGTH],
	String:ItemLoadoutSlot[STORE_MAX_LOADOUTSLOT_LENGTH],
	ItemPrice,
	ItemCategoryId,
	bool:ItemIsBuyable,
	bool:ItemIsTradeable,
	bool:ItemIsRefundable,
	ItemFlags,
	bool:ItemDisableServerRestriction
}

int g_items[MAX_ITEMS][Item];
int g_itemCount = -1;

//Loadouts
enum Loadout
{
	LoadoutId,
	String:LoadoutDisplayName[STORE_MAX_DISPLAY_NAME_LENGTH],
	String:LoadoutGame[STORE_MAX_LOADOUTGAME_LENGTH],
	String:LoadoutClass[STORE_MAX_LOADOUTCLASS_LENGTH],
	LoadoutTeam
}

int g_loadouts[MAX_LOADOUTS][Loadout];
int g_loadoutCount = -1;

//Forward Handles
Handle g_dbInitializedForward;
Handle g_reloadItemsForward;
Handle g_reloadItemsPostForward;

//MySQL globals
Handle g_hSQL;
int g_reconnectCounter;

//Category Restriction Cache
Handle hCategoriesCache;
Handle hCategoriesCache2;

//Item Restriction Cache
Handle hItemsCache;
Handle hItemsCache2;

//Config Globals
char g_baseURL[256];

//Plugin Info
public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = STORE_AUTHORS,
	description = PLUGIN_DESCRIPTION,
	version = STORE_VERSION,
	url = STORE_URL
};

//Ask Plugin Load 2
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//General Natives
	CreateNative("Store_ReloadCacheStacks", Native_ReloadCacheStacks);
	CreateNative("Store_RegisterPluginModule", Native_RegisterPluginModule);
	CreateNative("Store_GetStoreBaseURL", Native_GetStoreBaseURL);
	
	//Client Natives
	CreateNative("Store_Register", Native_Register);
	CreateNative("Store_RegisterClient", Native_RegisterClient);
	CreateNative("Store_GetClientAccountID", Native_GetClientAccountID);
	CreateNative("Store_GetClientUserID", Native_GetClientUserID);
	
	//Category Natives
	CreateNative("Store_GetCategories", Native_GetCategories);
	CreateNative("Store_GetCategoryDisplayName", Native_GetCategoryDisplayName);
	CreateNative("Store_GetCategoryDescription", Native_GetCategoryDescription);
	CreateNative("Store_GetCategoryPluginRequired", Native_GetCategoryPluginRequired);
	CreateNative("Store_GetCategoryServerRestriction", Native_GetCategoryServerRestriction);
	CreateNative("Store_GetCategoryPriority", Native_GetCategoryPriority);
	
	//Item Natives
	CreateNative("Store_GetItems", Native_GetItems);
	CreateNative("Store_GetItemName", Native_GetItemName);
	CreateNative("Store_GetItemDisplayName", Native_GetItemDisplayName);
	CreateNative("Store_GetItemDescription", Native_GetItemDescription);
	CreateNative("Store_GetItemType", Native_GetItemType);
	CreateNative("Store_GetItemLoadoutSlot", Native_GetItemLoadoutSlot);
	CreateNative("Store_GetItemPrice", Native_GetItemPrice);
	CreateNative("Store_GetItemCategory", Native_GetItemCategory);
	CreateNative("Store_GetItemPriority", Native_GetItemPriority);
	CreateNative("Store_GetItemServerRestriction", Native_GetItemServerRestriction);
	
	//Item Check Natives
	CreateNative("Store_IsItemBuyable", Native_IsItemBuyable);
	CreateNative("Store_IsItemTradeable", Native_IsItemTradeable);
	CreateNative("Store_IsItemRefundable", Native_IsItemRefundable);
	
	//Item Write Natives
	CreateNative("Store_GetItemAttributes", Native_GetItemAttributes);
	CreateNative("Store_WriteItemAttributes", Native_WriteItemAttributes);
	
	//Loadout Natives
	CreateNative("Store_GetLoadouts", Native_GetLoadouts);
	CreateNative("Store_GetLoadoutDisplayName", Native_GetLoadoutDisplayName);
	CreateNative("Store_GetLoadoutGame", Native_GetLoadoutGame);
	CreateNative("Store_GetLoadoutClass", Native_GetLoadoutClass);
	CreateNative("Store_GetLoadoutTeam", Native_GetLoadoutTeam);
	
	//Client Loadout Natives
	CreateNative("Store_GetClientLoadouts", Native_GetClientLoadouts);
	
	//User Natives
	CreateNative("Store_GetUserItems", Native_GetUserItems);
	CreateNative("Store_GetUserItemsCount", Native_GetUserItemsCount);
	CreateNative("Store_GetCredits", Native_GetCredits);
	CreateNative("Store_GetCreditsEx", Native_GetCreditsEx);
	
	//Give Credits Natives
	CreateNative("Store_GiveCredits", Native_GiveCredits);
	CreateNative("Store_GiveCreditsToUsers", Native_GiveCreditsToUsers);
	CreateNative("Store_GiveDifferentCreditsToUsers", Native_GiveDifferentCreditsToUsers);
	CreateNative("Store_GiveItem", Native_GiveItem);
	
	//Remove Credits Natives
	CreateNative("Store_RemoveCredits", Native_RemoveCredits);
	CreateNative("Store_RemoveCreditsFromUsers", Native_RemoveCreditsFromUsers);
	CreateNative("Store_RemoveDifferentCreditsFromUsers", Native_RemoveDifferentCreditsFromUsers);
	
	//Item Natives
	CreateNative("Store_BuyItem", Native_BuyItem);
	CreateNative("Store_RemoveUserItem", Native_RemoveUserItem);
	
	//Item Equipped Natives
	CreateNative("Store_SetItemEquippedState", Native_SetItemEquippedState);
	CreateNative("Store_GetEquippedItemsByType", Native_GetEquippedItemsByType);
	
	//SQL Database Natives
	CreateNative("Store_SQLTQuery", Native_SQLTQuery);
	CreateNative("Store_SQLEscapeString", Native_SQLEscapeString);
	
	//Process Restriction Natives
	CreateNative("Store_ProcessCategory", Native_ProcessCategory);
	CreateNative("Store_ProcessItem", Native_ProcessItem);
	
	//Forwards
	g_dbInitializedForward = CreateGlobalForward("Store_OnDatabaseInitialized", ET_Event);
	g_reloadItemsForward = CreateGlobalForward("Store_OnReloadItems", ET_Event);
	g_reloadItemsPostForward = CreateGlobalForward("Store_OnReloadItemsPost", ET_Event);
	
	//Library
	RegPluginLibrary("store-backend");
	
	return APLRes_Success;
}

//On Plugin Start
public void OnPluginStart()
{
	CreateConVar(PLUGIN_VERSION_CONVAR, STORE_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	LoadTranslations("common.phrases");
	LoadTranslations("store.phrases");

	RegAdminCmd("store_reloaditems", Command_ReloadItems, ADMFLAG_RCON, "Reloads store item cache.");
	RegAdminCmd("sm_store_reloaditems", Command_ReloadItems, ADMFLAG_RCON, "Reloads store item cache.");
	
	hCategoriesCache = CreateArray();
	hCategoriesCache2 = CreateArray();
	
	hItemsCache = CreateArray();
	hItemsCache2 = CreateArray();
	
	LoadConfig();
}

void LoadConfig()
{
	Handle kv = CreateKeyValues("root");

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/store/backend.cfg");

	if (!FileToKeyValues(kv, path))
	{
		CloseHandle(kv);
		SetFailState("Can't read config file %s", path);
	}
	
	KvGetString(kv, "base_url", g_baseURL, sizeof(g_baseURL));
	
	CloseHandle(kv);
}

//On All Plugins Loaded
public void OnAllPluginsLoaded()
{
	ConnectSQL();
}

//On Plugin End
public void OnPluginEnd()
{
	Store_LogWarning("WARNING: Please change the map or restart the server, you cannot reload store-backend while the map is loaded. (CRASH WARNING)");
}

//On Map Start
public void OnMapStart()
{
	if (g_hSQL != null)
	{
		ReloadCacheStacks(-1);
	}
}

//Function - Registration of new clients from AccountID's and names manually.
void Register(int accountId, const char[] name = "", int credits = 0)
{
	new String:safeName[2 * 32 + 1];
	SQL_EscapeString(g_hSQL, name, safeName, sizeof(safeName));

	new String:sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_Register, accountId, safeName, credits, safeName);
	Store_Local_TQuery("Register", SQLCall_Registration, sQuery, _, DBPrio_High);
}

//Function - Registration of new clients from client index.
void RegisterClient(int client, int credits = 0)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}
		
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	Register(GetSteamAccountID(client), name, credits);
}

//Query - callback for clients registered.
public void SQLCall_Registration(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		Store_LogError("SQL Error on Register: %s", error);
	}
}

//Function - Pull the categories for usage in other plugins. This function will re-cache the SQL database if needed.
void GetCategories(int client, Store_GetItemsCallback callback = INVALID_FUNCTION, Handle plugin = null, bool loadFromCache = true, char[] sPriority, any data = 0)
{
	if (loadFromCache && g_categoryCount != -1)
	{
		if (callback == INVALID_FUNCTION)
		{
			return;
		}
		
		int[] categories = new int[g_categoryCount];
		int count = 0;

		for (int category = 0; category < g_categoryCount; category++)
		{
			categories[count] = g_categories[category][CategoryId];
			count++;
		}

		Call_StartFunction(plugin, callback);
		Call_PushArray(categories, count);
		Call_PushCell(count);
		Call_PushCell(data);
		Call_Finish();
		
		char sName[MAX_NAME_LENGTH];
		if (client > 0)
		{
			GetClientName(client, sName, sizeof(sName));
		}
		
		Store_LogDebug("Categories Pulled for '%s': Count = %i - LoadFromCache: %s - Priority String: %s", strlen(sName) != 0 ? sName: "Console", count, loadFromCache ? "True" : "False", strlen(sPriority) != 0 ? sPriority : "N/A");
	}
	else
	{
		Handle hPack = CreateDataPack();
		WritePackFunction(hPack, callback);
		WritePackCell(hPack, _:plugin);
		WritePackCell(hPack, _:data);
		
		char sQuery[MAX_QUERY_SIZES];
		Format(sQuery, sizeof(sQuery), sQuery_GetCategories, sPriority);
		Store_Local_TQuery("GetCategories", SQLCall_RetrieveCategories, sQuery, hPack);
	}
	
	if (client != -1)
	{
		CReplyToCommand(client, "%t%t", (client != 0) ? "Store Tag Colored" : "Store Tag", "Reloaded categories");
	}
}

//Query - callback for categories retrieved.
public void SQLCall_RetrieveCategories(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		CloseHandle(data);
		Store_LogError("SQL Error on GetCategories: %s", error);
		return;
	}

	ResetPack(data);

	Store_GetItemsCallback callback = view_as<Store_GetItemsCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);

	CloseHandle(data);

	g_categoryCount = 0;

	while (SQL_FetchRow(hndl))
	{
		g_categories[g_categoryCount][CategoryId] = SQL_FetchInt(hndl, 0);
		g_categories[g_categoryCount][CategoryPriority] = SQL_FetchInt(hndl, 1);
		SQL_FetchString(hndl, 2, g_categories[g_categoryCount][CategoryDisplayName], STORE_MAX_DISPLAY_NAME_LENGTH);
		SQL_FetchString(hndl, 3, g_categories[g_categoryCount][CategoryDescription], STORE_MAX_DESCRIPTION_LENGTH);
		SQL_FetchString(hndl, 4, g_categories[g_categoryCount][CategoryRequirePlugin], STORE_MAX_REQUIREPLUGIN_LENGTH);
		g_categories[g_categoryCount][CategoryDisableServerRestriction] = view_as<bool>SQL_FetchInt(hndl, 5);

		g_categoryCount++;
	}

	GetCategories(-1, callback, plugin, true, "", arg);
}

//Function - Converts a category ID to an index.
int GetCategoryIndex(int id)
{
	for (int i = 0; i < g_categoryCount; i++)
	{
		if (g_categories[i][CategoryId] == id)
		{
			return i;
		}
	}

	return -1;
}

//Function - Pull the items for usage in other plugins. This function will re-cache the SQL database if needed.
void GetItems(int client, Handle filter = null, Store_GetItemsCallback callback = INVALID_FUNCTION, Handle plugin = null, bool loadFromCache = true, const char[] sPriority, any data = 0)
{
	if (loadFromCache && g_itemCount != -1)
	{
		if (callback == INVALID_FUNCTION)
		{
			return;
		}
		
		int categoryId;
		bool categoryFilter = filter == null ? false : GetTrieValue(filter, "category_id", categoryId);

		bool isBuyable;
		bool buyableFilter = filter == null ? false : GetTrieValue(filter, "is_buyable", isBuyable);

		bool isTradeable;
		bool tradeableFilter = filter == null ? false : GetTrieValue(filter, "is_tradeable", isTradeable);

		bool isRefundable;
		bool refundableFilter = filter == null ? false : GetTrieValue(filter, "is_refundable", isRefundable);

		char type[STORE_MAX_TYPE_LENGTH];
		bool typeFilter = filter == null ? false : GetTrieString(filter, "type", type, sizeof(type));

		int flags;
		bool flagsFilter = filter == null ? false : GetTrieValue(filter, "flags", flags);

		CloseHandle(filter);

		int[] items = new int[g_itemCount];
		
		int count = 0;
		
		for (int item = 0; item < g_itemCount; item++)
		{
			if ((!categoryFilter || categoryId == g_items[item][ItemCategoryId]) && (!buyableFilter || isBuyable == g_items[item][ItemIsBuyable]) && (!tradeableFilter || isTradeable == g_items[item][ItemIsTradeable]) && (!refundableFilter || isRefundable == g_items[item][ItemIsRefundable]) && (!typeFilter || StrEqual(type, g_items[item][ItemType])) && (!flagsFilter || !g_items[item][ItemFlags] || (flags & g_items[item][ItemFlags])))
			{
				items[count] = g_items[item][ItemId];
				count++;
			}
		}

		Call_StartFunction(plugin, callback);
		Call_PushArray(items, count);
		Call_PushCell(count);
		Call_PushCell(data);
		Call_Finish();
		
		char sName[MAX_NAME_LENGTH];
		if (client > 0)
		{
			GetClientName(client, sName, sizeof(sName));
		}
		
		Store_LogDebug("Items Pulled for '%s': Count = %i - LoadFromCache: %s - Priority String: %s", strlen(sName) != 0 ? sName : "Console", count, loadFromCache ? "True" : "False", strlen(sPriority) != 0 ? sPriority : "N/A");
	}
	else
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, _:filter);
		WritePackFunction(hPack, callback);
		WritePackCell(hPack, _:plugin);
		WritePackCell(hPack, _:data);
		
		char sQuery[MAX_QUERY_SIZES];
		Format(sQuery, sizeof(sQuery), sQuery_GetItems, sPriority);
		Store_Local_TQuery("GetItems", SQLCall_RetrieveItems, sQuery, hPack);
	}
	
	if (client != -1)
	{
		CReplyToCommand(client, "%t%t", (client != 0) ? "Store Tag Colored" : "Store Tag", "Reloaded items");
	}
}

//Query - callback for items retrieved.
public void SQLCall_RetrieveItems(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		CloseHandle(data);
		Store_LogError("SQL Error on GetItems: %s", error);
		return;
	}

	Call_StartForward(g_reloadItemsForward);
	Call_Finish();
	
	ResetPack(data);
	
	Handle filter = view_as<Handle>ReadPackCell(data);
	Store_GetItemsCallback callback = view_as<Store_GetItemsCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);

	CloseHandle(data);

	g_itemCount = 0;

	while (SQL_FetchRow(hndl))
	{
		g_items[g_itemCount][ItemId] = SQL_FetchInt(hndl, 0);
		g_items[g_itemCount][ItemPriority] = SQL_FetchInt(hndl, 1);
		SQL_FetchString(hndl, 2, g_items[g_itemCount][ItemName], STORE_MAX_NAME_LENGTH);
		SQL_FetchString(hndl, 3, g_items[g_itemCount][ItemDisplayName], STORE_MAX_DISPLAY_NAME_LENGTH);
		SQL_FetchString(hndl, 4, g_items[g_itemCount][ItemDescription], STORE_MAX_DESCRIPTION_LENGTH);
		SQL_FetchString(hndl, 5, g_items[g_itemCount][ItemType], STORE_MAX_TYPE_LENGTH);
		SQL_FetchString(hndl, 6, g_items[g_itemCount][ItemLoadoutSlot], STORE_MAX_LOADOUTSLOT_LENGTH);
		g_items[g_itemCount][ItemPrice] = SQL_FetchInt(hndl, 7);
		g_items[g_itemCount][ItemCategoryId] = SQL_FetchInt(hndl, 8);

		if (!SQL_IsFieldNull(hndl, 9))
		{
			int attrsLength = SQL_FetchInt(hndl, 10);
			
			char[] attrs = new char[attrsLength + 1];
			SQL_FetchString(hndl, 9, attrs, attrsLength+1);

			Store_CallItemAttrsCallback(g_items[g_itemCount][ItemType], g_items[g_itemCount][ItemName], attrs);
		}

		g_items[g_itemCount][ItemIsBuyable] = bool:SQL_FetchInt(hndl, 11);
		g_items[g_itemCount][ItemIsTradeable] = bool:SQL_FetchInt(hndl, 12);
		g_items[g_itemCount][ItemIsRefundable] = bool:SQL_FetchInt(hndl, 13);

		char flags[11];
		SQL_FetchString(hndl, 14, flags, sizeof(flags));
		g_items[g_itemCount][ItemFlags] = ReadFlagString(flags);
		
		g_items[g_itemCount][ItemDisableServerRestriction] = bool:SQL_FetchInt(hndl, 15);
				
		g_itemCount++;
	}

	Call_StartForward(g_reloadItemsPostForward);
	Call_Finish();

	GetItems(-1, filter, callback, plugin, true, "", arg);
}

//Function - Retrieves cached stacks in the database for category/item restrictions.
void GetCacheStacks()
{
	char sQuery[MAX_QUERY_SIZES];
	
	Format(sQuery, sizeof(sQuery), sQuery_CacheRestrictionsCategories);
	Store_Local_TQuery("GetCategoryCacheStacks", SQLCall_GetCategoryRestrictions, sQuery);
	
	Format(sQuery, sizeof(sQuery), sQuery_CacheRestrictionsItems);
	Store_Local_TQuery("GetItemCacheStacks", SQLCall_GetItemRestrictions, sQuery);
}

//Query - callback to retrieve category restrictions.
public void SQLCall_GetCategoryRestrictions(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_GetCategoryRestrictions: %s", error);
		return;
	}
	
	while (SQL_FetchRow(hndl) && !SQL_IsFieldNull(hndl, 0))
	{
		int CategoryID = SQL_FetchInt(hndl, 0);
		int ServerID = SQL_FetchInt(hndl, 1);
		
		PushArrayCell(hCategoriesCache, CategoryID);
		PushArrayCell(hCategoriesCache2, ServerID);
	}
}

//Query - callback to retrieve item restrictions.
public void SQLCall_GetItemRestrictions(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_GetItemRestrictions: %s", error);
		return;
	}
	
	while (SQL_FetchRow(hndl) && !SQL_IsFieldNull(hndl, 0))
	{
		int ItemID = SQL_FetchInt(hndl, 0);
		int ServerID = SQL_FetchInt(hndl, 1);
		
		PushArrayCell(hItemsCache, ItemID);
		PushArrayCell(hItemsCache2, ServerID);
	}
}

//Function - Converts an item ID to an index.
int GetItemIndex(int id)
{
	for (int i = 0; i < g_itemCount; i++)
	{
		if (g_items[i][ItemId] == id)
		{
			return i;
		}
	}

	return -1;
}

//Function - Retrieve an items attributes.
void GetItemAttributes(const char[] itemName, Store_ItemGetAttributesCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackString(hPack, itemName);
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);

	int itemNameLength = 2 * strlen(itemName) + 1;

	char[] itemNameSafe = new char[itemNameLength];
	SQL_EscapeString(g_hSQL, itemName, itemNameSafe, itemNameLength);
	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GetItemAttributes, itemNameSafe);
	Store_Local_TQuery("GetItemAttributes", SQLCall_GetItemAttributes, sQuery, hPack);
}

//Query - callback while retrieving an items attributes.
public void SQLCall_GetItemAttributes(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);
	
	char itemName[STORE_MAX_NAME_LENGTH];
	ReadPackString(data, itemName, sizeof(itemName));
	
	Store_ItemGetAttributesCallback callback = view_as<Store_ItemGetAttributesCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);
	
	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_GetItemAttributes: %s", error);
		return;
	}
	
	if (SQL_FetchRow(hndl) && !SQL_IsFieldNull(hndl, 0))
	{
		int attrsLength = SQL_FetchInt(hndl, 1);
		
		char[] attrs = new char[attrsLength + 1];
		SQL_FetchString(hndl, 0, attrs, attrsLength+1);
		
		if (callback != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, callback);
			Call_PushString(itemName);
			Call_PushString(attrs);
			Call_PushCell(arg);
			Call_Finish();
		}
	}
}

//Function - Write to an items attributes.
void WriteItemAttributes(const char[] itemName, const char[] attrs, Store_BuyItemCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);

	int itemNameLength = 2 * strlen(itemName) + 1;
	char[] itemNameSafe = new char[itemNameLength];
	SQL_EscapeString(g_hSQL, itemName, itemNameSafe, itemNameLength);

	int attrsLength = 10 * 1024;
	char[] attrsSafe = new char[2 * attrsLength + 1];
	SQL_EscapeString(g_hSQL, attrs, attrsSafe, 2 * attrsLength + 1);
	
	char[] sQuery = new char[attrsLength + MAX_QUERY_SIZES];
	Format(sQuery, attrsLength + MAX_QUERY_SIZES, sQuery_WriteItemAttributes, attrsSafe, itemNameSafe);
	Store_Local_TQuery("WriteItemAttributes", SQLCall_WriteItemAttributes, sQuery, hPack);
}

//Query - callback to write an items attributes.
public void SQLCall_WriteItemAttributes(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);

	Store_BuyItemCallback callback = view_as<Store_BuyItemCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);

	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on WriteItemAttributes: %s", error);
		return;
	}

	if (callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(true);
		Call_PushCell(arg);
		Call_Finish();
	}
}

//Function - Pull the loadouts for a client for usage in other plugins. This function will re-cache the SQL database if needed.
void GetLoadouts(Handle filter, Store_GetItemsCallback callback = INVALID_FUNCTION, Handle plugin = null, bool loadFromCache = true, any data = 0)
{
	if (loadFromCache && g_loadoutCount != -1)
	{
		if (callback == INVALID_FUNCTION)
		{
			return;
		}

		int[] loadouts = new int[g_loadoutCount];
		int count = 0;

		char game[32];
		bool gameFilter = filter == null ? false : GetTrieString(filter, "game", game, sizeof(game));

		char class[32];
		bool classFilter = filter == null ? false : GetTrieString(filter, "class", class, sizeof(class));

		CloseHandle(filter);

		for (int loadout = 0; loadout < g_loadoutCount; loadout++)
		{
			if ((!gameFilter || StrEqual(game, "") || StrEqual(g_loadouts[loadout][LoadoutGame], "") || StrEqual(game, g_loadouts[loadout][LoadoutGame])) && (!classFilter || StrEqual(class, "") || StrEqual(g_loadouts[loadout][LoadoutClass], "") || StrEqual(class, g_loadouts[loadout][LoadoutClass])))
			{
				loadouts[count] = g_loadouts[loadout][LoadoutId];
				count++;
			}
		}

		Call_StartFunction(plugin, callback);
		Call_PushArray(loadouts, count);
		Call_PushCell(count);
		Call_PushCell(data);
		Call_Finish();
		
		Store_LogDebug("Loadouts Pulled: Count = %i - LoadFromCache: %s", count, loadFromCache ? "True" : "False");
	}
	else
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, _:filter);
		WritePackFunction(hPack, callback);
		WritePackCell(hPack, _:plugin);
		WritePackCell(hPack, _:data);
				
		char sQuery[MAX_QUERY_SIZES];
		Format(sQuery, sizeof(sQuery), sQuery_GetLoadouts);
		Store_Local_TQuery("GetLoadouts", SQLCall_GetLoadouts, sQuery, hPack);
	}
}

//Query - callback while getting a clients loadouts.
public void SQLCall_GetLoadouts(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		CloseHandle(data);

		Store_LogError("SQL Error on SQLCall_GetLoadouts: %s", error);
		return;
	}
	
	ResetPack(data);
	
	Handle filter = view_as<Handle>ReadPackCell(data);
	Store_GetItemsCallback callback = view_as<Store_GetItemsCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int data2 = ReadPackCell(data);
	
	CloseHandle(data);
	
	g_loadoutCount = 0;
	
	while (SQL_FetchRow(hndl))
	{
		g_loadouts[g_loadoutCount][LoadoutId] = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, g_loadouts[g_loadoutCount][LoadoutDisplayName], STORE_MAX_DISPLAY_NAME_LENGTH);
		SQL_FetchString(hndl, 2, g_loadouts[g_loadoutCount][LoadoutGame], STORE_MAX_LOADOUTGAME_LENGTH);
		SQL_FetchString(hndl, 3, g_loadouts[g_loadoutCount][LoadoutClass], STORE_MAX_LOADOUTCLASS_LENGTH);
		g_loadouts[g_loadoutCount][LoadoutTeam] = SQL_IsFieldNull(hndl, 4) ? -1 : SQL_FetchInt(hndl, 4);
		
		g_loadoutCount++;
	}
	
	GetLoadouts(filter, callback, plugin, true, data2);
}

//Function - Converts a loadout ID to an index.
int GetLoadoutIndex(int id)
{
	for (int i = 0; i < g_loadoutCount; i++)
	{
		if (g_loadouts[i][LoadoutId] == id)
		{
			return i;
		}
	}

	return -1;
}

//Function - Gets a clients loadouts.
void GetClientLoadouts(int accountId, Store_GetUserLoadoutsCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, accountId);
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);
	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GetClientLoadouts, accountId);
	Store_Local_TQuery("GetClientLoadouts", SQLCall_GetClientLoadouts, sQuery, hPack);
}

//Query - callback while retrieving client loadouts.
public void SQLCall_GetClientLoadouts(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);
	
	int accountId = ReadPackCell(data);
	Store_GetUserLoadoutsCallback callback = view_as<Store_GetUserLoadoutsCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);
	
	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_GetClientLoadouts: %s", error);
		return;
	}
	
	int count = SQL_GetRowCount(hndl);
	
	int[] ids = new int[count];

	int index = 0;
	while (SQL_FetchRow(hndl))
	{
		ids[index] = SQL_FetchInt(hndl, 0);
		index++;
	}

	Call_StartFunction(plugin, callback);
	Call_PushCell(accountId);
	Call_PushArray(ids, count);
	Call_PushCell(count);
	Call_PushCell(_:arg);
	Call_Finish();
}

//Function - Retrieves a clients items in the database. There is no cache to this as it's required to load it live.
void GetUserItems(Handle filter, int accountId, int loadoutId, Store_GetUserItemsCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, _:filter);
	WritePackCell(hPack, accountId);
	WritePackCell(hPack, loadoutId);
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);
	
	if (g_itemCount == -1)
	{
		Store_LogWarning("Store_GetUserItems has been called before item loading.");
		GetItems(-1, _, ReloadUserItems, _, true, "", hPack);

		return;
	}
	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GetUserItems, loadoutId, accountId);

	int categoryId;
	if (GetTrieValue(filter, "category_id", categoryId))
	{
		Format(sQuery, sizeof(sQuery), sQuery_GetUserItems_categoryId, sQuery, categoryId);
	}
	
	bool isBuyable;
	if (GetTrieValue(filter, "is_buyable", isBuyable))
	{
		Format(sQuery, sizeof(sQuery), sQuery_GetUserItems_isBuyable, sQuery, isBuyable);
	}
	
	bool isTradeable;
	if (GetTrieValue(filter, "is_tradeable", isTradeable))
	{
		Format(sQuery, sizeof(sQuery), sQuery_GetUserItems_isTradeable, sQuery, isTradeable);
	}
	
	bool isRefundable;
	if (GetTrieValue(filter, "is_refundable", isRefundable))
	{
		Format(sQuery, sizeof(sQuery), sQuery_GetUserItems_isRefundable, sQuery, isRefundable);
	}
	
	char type[STORE_MAX_TYPE_LENGTH];
	if (GetTrieString(filter, "type", type, sizeof(type)))
	{
		int typeLength = 2 * strlen(type) + 1;
		
		char[] buffer = new char[typeLength];
		SQL_EscapeString(g_hSQL, type, buffer, typeLength);

		Format(sQuery, sizeof(sQuery), sQuery_GetUserItems_type, sQuery, buffer);
	}

	CloseHandle(filter);
	
	Format(sQuery, sizeof(sQuery), sQuery_GetUserItems_GroupByID, sQuery);
	Store_Local_TQuery("GetUserItems", SQLCall_GetUserItems, sQuery, hPack, DBPrio_High);
}

//Function - Resets a data pack for usage.
public ReloadUserItems(int[] ids, int count, any hPack)
{
	ResetPack(hPack);

	Handle filter = view_as<Handle>ReadPackCell(hPack);
	int accountId = ReadPackCell(hPack);
	int loadoutId = ReadPackCell(hPack);
	Store_GetUserItemsCallback callback = view_as<Store_GetUserItemsCallback>ReadPackFunction(hPack);
	Handle plugin = view_as<Handle>ReadPackCell(hPack);
	int arg = ReadPackCell(hPack);

	CloseHandle(hPack);

	GetUserItems(filter, accountId, loadoutId, callback, plugin, arg);
}

//Query - callback to get a users items.
public void SQLCall_GetUserItems(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);
	ReadPackCell(data);
	ReadPackCell(data);
	
	int loadoutId = ReadPackCell(data);
	Store_GetUserItemsCallback callback = view_as<Store_GetUserItemsCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);
	
	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_GetUserItems: %s", error);
		return;
	}
	
	int count = SQL_GetRowCount(hndl);
	
	int[] ids = new int[count];
	bool[] equipped = new bool[count];
	int[] itemCount = new int[count];

	int index = 0;
	while (SQL_FetchRow(hndl))
	{
		ids[index] = SQL_FetchInt(hndl, 0);
		equipped[index] = view_as<bool>SQL_FetchInt(hndl, 1);
		itemCount[index] = SQL_FetchInt(hndl, 2);

		index++;
	}

	Call_StartFunction(plugin, callback);
	Call_PushArray(ids, count);
	Call_PushArray(equipped, count);
	Call_PushArray(itemCount, count);
	Call_PushCell(count);
	Call_PushCell(loadoutId);
	Call_PushCell(_:arg);
	Call_Finish();
}

//Function - Retrieves a clients items count in the database. There is no cache to this as it's required to load it live.
void GetUserItemsCount(int accountId, const char[] itemName, Store_GetUserItemsCountCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);

	int itemNameLength = 2 * strlen(itemName) + 1;
	
	char[] itemNameSafe = new char[itemNameLength];
	SQL_EscapeString(g_hSQL, itemName, itemNameSafe, itemNameLength);
	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GetUserItemsCount, itemNameSafe, accountId);
	Store_Local_TQuery("GetUserItemsCount", SQLCall_GetUserItemsCount, sQuery, hPack, DBPrio_High);
}

//Query - callback for getting a clients items count.
public void SQLCall_GetUserItemsCount(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);

	Store_GetUserItemsCountCallback callback = view_as<Store_GetUserItemsCountCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);

	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_GetUserItemsCount: %s", error);
		return;
	}

	if (SQL_FetchRow(hndl))
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(SQL_FetchInt(hndl, 0));
		Call_PushCell(_:arg);
		Call_Finish();
	}
}

//Function - Retrieves a clients credits in the database. There is no cache to this as it's required to load it live.
void GetCredits(int accountId, Store_GetCreditsCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);
	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GetCredits, accountId);
	Store_Local_TQuery("GetCredits", SQLCall_GetCredits, sQuery, hPack, DBPrio_High);
}

//Query - callback to retrieve a clients credits.
public void SQLCall_GetCredits(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);

	Store_GetCreditsCallback callback = view_as<Store_GetCreditsCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);
	
	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on GetCredits: %s", error);
		return;
	}
	
	if (SQL_FetchRow(hndl))
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(SQL_FetchInt(hndl, 0));
		Call_PushCell(_:arg);
		Call_Finish();
	}
}

//Function - Processes an item purchase in the database.
void BuyItem(int accountId, int itemId, Store_BuyItemCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, itemId);
	WritePackCell(hPack, accountId);
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);

	GetCredits(accountId, OnGetCreditsForItemBuy, _, hPack);
}

//Callback - callback to purchase an item for a client.
public OnGetCreditsForItemBuy(int credits, any hPack)
{
	ResetPack(hPack);

	int itemId = ReadPackCell(hPack);
	int accountId = ReadPackCell(hPack);
	Store_BuyItemCallback callback = view_as<Store_BuyItemCallback>ReadPackFunction(hPack);
	Handle plugin = view_as<Handle>ReadPackCell(hPack);
	int arg = ReadPackCell(hPack);

	if (credits < g_items[GetItemIndex(itemId)][ItemPrice])
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(0);
		Call_PushCell(_:arg);
		Call_Finish();

		return;
	}

	RemoveCredits(accountId, g_items[GetItemIndex(itemId)][ItemPrice], OnBuyItemGiveItem, _, hPack);
}

//Callback - On item purchase, remove credits from client and give them the item.
public OnBuyItemGiveItem(int accountId, int credits, bool bNegative, any hPack)
{
	ResetPack(hPack);

	int itemId = ReadPackCell(hPack);
	GiveItem(accountId, itemId, Store_Shop, OnGiveItemFromBuyItem, _, hPack);
}

//Callback - On credits removed, give item.
public OnGiveItemFromBuyItem(int accountId, any hPack)
{
	ResetPack(hPack);
	ReadPackCell(hPack);
	ReadPackCell(hPack);
	
	Store_BuyItemCallback callback = view_as<Store_BuyItemCallback>ReadPackFunction(hPack);
	Handle plugin = view_as<Handle>ReadPackCell(hPack);
	int arg = ReadPackCell(hPack);

	CloseHandle(hPack);

	Call_StartFunction(plugin, callback);
	Call_PushCell(1);
	Call_PushCell(_:arg);
	Call_Finish();
}

//Function - Processes an item removal from the database.
void RemoveUserItem(int accountId, int itemId, Store_UseItemCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, accountId);
	WritePackCell(hPack, itemId);
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);

	UnequipItem(accountId, itemId, -1, OnRemoveUserItem, _, hPack);
}

//Callback - Remove client item from database.
public OnRemoveUserItem(int accountId, int itemId, int loadoutId, any hPack)
{
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_RemoveUserItem, itemId, accountId);
	Store_Local_TQuery("RemoveUserItemUnequipCallback", SQLCall_RemoveUserItem, sQuery, hPack, DBPrio_High);
}

//Query - callback when an item is removed from a client.
public void SQLCall_RemoveUserItem(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);

	int accountId = ReadPackCell(data);
	int itemId = ReadPackCell(data);
	Store_UseItemCallback callback = view_as<Store_UseItemCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);

	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_RemoveUserItem: %s", error);
		return;
	}

	Call_StartFunction(plugin, callback);
	Call_PushCell(accountId);
	Call_PushCell(itemId);
	Call_PushCell(_:arg);
	Call_Finish();
}

//Function - Sets an items equipped state for a client.
void SetItemEquippedState(int accountId, int itemId, int loadoutId, bool isEquipped, Store_EquipItemCallback callback, Handle plugin = null, any data = 0)
{
	switch (isEquipped)
	{
		case true: EquipItem(accountId, itemId, loadoutId, callback, plugin, data);
		case false: UnequipItem(accountId, itemId, loadoutId, callback, plugin, data);
	}
}

//Function - Equip an item on a client.
void EquipItem(int accountId, int itemId, int loadoutId, Store_EquipItemCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, accountId);
	WritePackCell(hPack, itemId);
	WritePackCell(hPack, loadoutId);
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);

	UnequipItem(accountId, itemId, loadoutId, OnUnequipItemToEquipNewItem, _, hPack);
}

//Callback - unequip an item for a client to equip a new one.
public OnUnequipItemToEquipNewItem(int accountId, int itemId, int loadoutId, any hPack)
{
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_EquipUnequipItem, loadoutId, accountId, itemId);
	Store_Local_TQuery("EquipUnequipItemCallback", SQLCall_EquipItem, sQuery, hPack, DBPrio_High);
}

//Query - callback when item is equipped.
public void SQLCall_EquipItem(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);

	int accountId = ReadPackCell(data);
	int itemId = ReadPackCell(data);
	int loadoutId = ReadPackCell(data);
	Store_GiveCreditsCallback callback = view_as<Store_GiveCreditsCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);

	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_EquipItem: %s", error);
		return;
	}

	Call_StartFunction(plugin, callback);
	Call_PushCell(accountId);
	Call_PushCell(itemId);
	Call_PushCell(loadoutId);
	Call_PushCell(_:arg);
	Call_Finish();
}

//Function - Unequip an item on a client.
void UnequipItem(int accountId, int itemId, int loadoutId, Store_EquipItemCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, accountId);
	WritePackCell(hPack, itemId);
	WritePackCell(hPack, loadoutId);
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);

	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_UnequipItem, accountId, itemId);

	if (loadoutId != -1)
	{
		Format(sQuery, sizeof(sQuery), sQuery_UnequipItem_loadoutId, sQuery, loadoutId);
	}
	
	Store_Local_TQuery("UnequipItem", SQLCall_UnequipItem, sQuery, hPack, DBPrio_High);
}

//Query - callback when an item is unequipped.
public void SQLCall_UnequipItem(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);

	int accountId = ReadPackCell(data);
	int itemId = ReadPackCell(data);
	int loadoutId = ReadPackCell(data);
	Store_GiveCreditsCallback callback = view_as<Store_GiveCreditsCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);

	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_UnequipItem: %s", error);
		return;
	}

	Call_StartFunction(plugin, callback);
	Call_PushCell(accountId);
	Call_PushCell(itemId);
	Call_PushCell(loadoutId);
	Call_PushCell(_:arg);
	Call_Finish();
}

//Function - Gets equipped items by type.
void GetEquippedItemsByType(int accountId, const char[] type, int loadoutId, Store_GetItemsCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);
		
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GetEquippedItemsByType, accountId, type, loadoutId);
	Store_Local_TQuery("GetEquipptedItemsByType", SQLCall_GetEquippedItemsByType, sQuery, hPack, DBPrio_High);
}

//Query - callback when items are equipped by type.
public void SQLCall_GetEquippedItemsByType(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);

	Store_GetItemsCallback callback = view_as<Store_GetItemsCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);

	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_GetEquippedItemsByType: %s", error);
		return;
	}

	int count = SQL_GetRowCount(hndl);
	int[] ids = new int[count];

	int index = 0;
	while (SQL_FetchRow(hndl))
	{
		ids[index] = SQL_FetchInt(hndl, 0);
		index++;
	}

	Call_StartFunction(plugin, callback);
	Call_PushArray(ids, count);
	Call_PushCell(count);
	Call_PushCell(arg);
	Call_Finish();
}

//Function - Give credits to a client.
void GiveCredits(int accountId, int credits, Store_GiveCreditsCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, accountId);
	WritePackCell(hPack, credits);
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);
	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GiveCredits, credits, accountId);
	Store_Local_TQuery("GiveCredits", SQLCall_GiveCredits, sQuery, hPack);
}

//Query - callback when a client is given credits.
public void SQLCall_GiveCredits(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);

	int accountId = ReadPackCell(data);
	int credits = ReadPackCell(data);
	Store_GiveCreditsCallback callback = view_as<Store_GiveCreditsCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);

	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_GiveCredits: %s", error);
		return;
	}

	if (callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(accountId);
		Call_PushCell(credits);
		Call_PushCell(_:arg);
		Call_Finish();
	}
}

//Function - Remove credits from a client.
void RemoveCredits(int accountId, int credits, Store_RemoveCreditsCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, accountId);
	WritePackCell(hPack, credits);
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);
	
	Store_LogDebug("Native - RemoveCredits - accountId = %d, credits = %d", accountId, credits);
	
	bool bIsNegative;
	if (Store_GetCreditsEx(accountId) < credits)
	{
		bIsNegative = true;
		WritePackCell(hPack, bIsNegative);
		
		char sQuery[MAX_QUERY_SIZES];
		Format(sQuery, sizeof(sQuery), sQuery_RemoveCredits_Negative, accountId);
		Store_Local_TQuery("RemoveCredits", SQLCall_RemoveCredits, sQuery, hPack);
		
		return;
	}
	
	WritePackCell(hPack, bIsNegative);

	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_RemoveCredits, credits, accountId);
	Store_Local_TQuery("RemoveCredits", SQLCall_RemoveCredits, sQuery, hPack);
}

//Query - callback when a client has credits removed.
public void SQLCall_RemoveCredits(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);

	int accountId = ReadPackCell(data);
	int credits = ReadPackCell(data);
	Store_RemoveCreditsCallback callback = view_as<Store_RemoveCreditsCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);
	int bIsNegative = view_as<bool>ReadPackCell(data);

	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_RemoveCredits: %s", error);
		return;
	}

	if (callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(accountId);
		Call_PushCell(credits);
		Call_PushCell(bIsNegative);
		Call_PushCell(_:arg);
		Call_Finish();
	}
}

//Function - Give an item to a client.
void GiveItem(int accountId, int itemId, Store_AcquireMethod acquireMethod = Store_Unknown, Store_AccountCallback callback, Handle plugin = null, any data = 0)
{
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, accountId);
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, _:plugin);
	WritePackCell(hPack, _:data);

	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GiveItem, itemId);
	
	switch (acquireMethod)
	{
		case Store_Shop: Format(sQuery, sizeof(sQuery), sQuery_GiveItem_Shop, sQuery);
		case Store_Trade: Format(sQuery, sizeof(sQuery), sQuery_GiveItem_Trade, sQuery);
		case Store_Gift: Format(sQuery, sizeof(sQuery), sQuery_GiveItem_Gift, sQuery);
		case Store_Admin: Format(sQuery, sizeof(sQuery), sQuery_GiveItem_Admin, sQuery);
		case Store_Web: Format(sQuery, sizeof(sQuery), sQuery_GiveItem_Web, sQuery);
		case Store_Unknown: Format(sQuery, sizeof(sQuery), sQuery_GiveItem_Unknown, sQuery);
	}

	Format(sQuery, sizeof(sQuery), sQuery_GiveItem_End, sQuery, accountId);
	Store_Local_TQuery("GiveItem", SQLCall_GiveItem, sQuery, hPack, DBPrio_High);
}

//Query - callback to give a client an item.
public void SQLCall_GiveItem(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);

	int accountId = ReadPackCell(data);
	Store_AccountCallback callback = view_as<Store_AccountCallback>ReadPackFunction(data);
	Handle plugin = view_as<Handle>ReadPackCell(data);
	int arg = ReadPackCell(data);
	
	CloseHandle(data);
	
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_GiveItem: %s", error);
		return;
	}
	
	if (callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(accountId);
		Call_PushCell(_:arg);
		Call_Finish();
	}
}

//Function - Give credits to users.
void GiveCreditsToUsers(int[] accountIds, int accountIdsLength, int credits)
{
	if (accountIdsLength == 0)
	{
		return;
	}
	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GiveCreditsToUsers, credits);

	for (int i = 0; i < accountIdsLength; i++)
	{
		Format(sQuery, sizeof(sQuery), "%s%d", sQuery, accountIds[i]);

		if (i < accountIdsLength - 1)
		{
			Format(sQuery, sizeof(sQuery), "%s, ", sQuery);
		}
	}

	Format(sQuery, sizeof(sQuery), sQuery_GiveCreditsToUsers_End, sQuery);
	Store_Local_TQuery("GiveCreditsToUsers", SQLCall_GiveCreditsToUsers, sQuery);
}

//Query - callback to give credits to users.
public void SQLCall_GiveCreditsToUsers(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_GiveCreditsToUsers: %s", error);
	}
}

//Function - Remove credits from users.
void RemoveCreditsFromUsers(int[] accountIds, int accountIdsLength, int credits)
{
	if (accountIdsLength == 0)
	{
		return;
	}
	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_RemoveCreditsFromUsers, credits);

	for (int i = 0; i < accountIdsLength; i++)
	{
		Format(sQuery, sizeof(sQuery), "%s%d", sQuery, accountIds[i]);

		if (i < accountIdsLength - 1)
		{
			Format(sQuery, sizeof(sQuery), "%s, ", sQuery);
		}
	}

	Format(sQuery, sizeof(sQuery), sQuery_RemoveCreditsFromUsers_End, sQuery);
	Store_Local_TQuery("RemoveCreditsFromUsers", SQLCall_RemoveCreditsFromUsers, sQuery);
}

public void SQLCall_RemoveCreditsFromUsers(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		Store_LogError("SQL Error on RemoveCreditsFromUsers: %s", error);
	}
}

//Function - Give different credits to users.
void GiveDifferentCreditsToUsers(int[] accountIds, int accountIdsLength, int[] credits)
{
	if (accountIdsLength == 0)
	{
		return;
	}
	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GiveDifferentCreditsToUsers);

	for (int i = 0; i < accountIdsLength; i++)
	{
		Format(sQuery, sizeof(sQuery), sQuery_RemoveDifferentCreditsFromUsers_accountIdsLength, sQuery, accountIds[i], credits[i]);
	}

	Format(sQuery, sizeof(sQuery), sQuery_GiveDifferentCreditsToUsers_End, sQuery);

	for (int i = 0; i < accountIdsLength; i++)
	{
		Format(sQuery, sizeof(sQuery), "%s%d", sQuery, accountIds[i]);

		if (i < accountIdsLength - 1)
		{
			Format(sQuery, sizeof(sQuery), "%s, ", sQuery);
		}
	}

	Format(sQuery, sizeof(sQuery), "%s)", sQuery);
	Store_Local_TQuery("GiveDifferentCreditsToUsers", SQLCall_GiveDifferentCreditsToUsers, sQuery);
}

//Query - callback to give different credits to users.
public void SQLCall_GiveDifferentCreditsToUsers(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		Store_LogError("SQL Error on GiveDifferentCreditsToUsers: %s", error);
	}
}

//Function - Remove different credits from users.
void RemoveDifferentCreditsFromUsers(int[] accountIds, int accountIdsLength, int[] credits)
{
	if (accountIdsLength == 0)
	{
		return;
	}
	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_RemoveDifferentCreditsFromUsers);

	for (int i = 0; i < accountIdsLength; i++)
	{
		Format(sQuery, sizeof(sQuery), sQuery_GiveDifferentCreditsToUsers_accountIdsLength, sQuery, accountIds[i], credits[i]);
	}

	Format(sQuery, sizeof(sQuery), sQuery_RemoveDifferentCreditsFromUsers_End, sQuery);

	for (int i = 0; i < accountIdsLength; i++)
	{
		Format(sQuery, sizeof(sQuery), "%s%d", sQuery, accountIds[i]);

		if (i < accountIdsLength - 1)
		{
			Format(sQuery, sizeof(sQuery), "%s, ", sQuery);
		}
	}

	Format(sQuery, sizeof(sQuery), "%s)", sQuery);
	Store_Local_TQuery("RemoveDifferentCreditsFromUsers", SQLCall_RemoveDifferentCreditsFromUsers, sQuery);
}

//Query - callback to give different credits to users.
public void SQLCall_RemoveDifferentCreditsFromUsers(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_RemoveDifferentCreditsFromUsers: %s", error);
	}
}

//Function - reload all caches for the backend module.
void ReloadCacheStacks(int client)
{
	GetCategories(client, _, _, false, "");
	GetItems(client, _, _, _, false, "");
	
	GetCacheStacks();
}

//Function - Connect to the SQL database for all modules to use.
void ConnectSQL()
{
	if (g_hSQL != null)
	{
		CloseHandle(g_hSQL);
		g_hSQL = null;
	}

	char sBuffer[64];
	Store_GetSQLEntry(sBuffer, sizeof(sBuffer));

	if (SQL_CheckConfig(sBuffer))
	{
		SQL_TConnect(SQLCall_ConnectToDatabase, sBuffer);
	}
	else
	{
		SetFailState("No config entry found for '%s' in databases.cfg.", sBuffer);
	}
}

//Query - callback when SQL database connects.
public void SQLCall_ConnectToDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
	if (g_reconnectCounter >= 5)
	{
		SetFailState("Error: Maximum amount of connections attempted, please check your SQL server & settings.");
		return;
	}
	
	if (hndl == null)
	{
		Store_LogError("Connection to SQL database has failed! Error: %s", error);
		
		g_reconnectCounter++;
		ConnectSQL();
		
		return;
	}
	
	SQL_SetCharset(hndl, "utf8");
	g_hSQL = CloneHandle(hndl);
	CloseHandle(hndl);
	
	Store_RegisterPluginModule(PLUGIN_NAME, PLUGIN_DESCRIPTION, PLUGIN_VERSION_CONVAR, STORE_VERSION);
	
	Call_StartForward(g_dbInitializedForward);
	Call_Finish();
	
	ReloadCacheStacks(-1);
	
	g_reconnectCounter = 1;
}

//Command - Reloads all items in the database.
public Action Command_ReloadItems(int client, int args)
{
	if (client != 0)
	{
		CPrintToChat(client, "%t%t", "Store Tag Colored", "Check console for reload outputs");
	}
	
	CReplyToCommand(client, "%t%t", (client != 0) ? "Store Tag Colored" : "Store Tag", "Reloading categories and items");
	ReloadCacheStacks(client);
	
	return Plugin_Handled;
}

//Function - Creates a query and creates a trace log with the specified name for debugging. (Hell of a lot easier)
void Store_Local_TQuery(const char[] sQueryName, SQLTCallback callback, const char[] sQuery, any data = 0, DBPriority prio = DBPrio_Normal)
{
	SQL_TQuery(g_hSQL, callback, sQuery, data, prio);
	Store_LogTrace("[SQL Query] - Name: '%s', Query --- %s", sQueryName, sQuery);
}

////////////////////
//Natives

//Native - Reload all cache stacks.
public int Native_ReloadCacheStacks(Handle plugin, numParams)
{
	ReloadCacheStacks(-1);
}

//Native - Register a new plugin module for web panel version control.
public int Native_RegisterPluginModule(Handle plugin, numParams)
{
	int ServerID = Store_GetServerID();
	
	int length;
	GetNativeStringLength(1, length);
	
	char[] sName = new char[length + 1];
	GetNativeString(1, sName, length + 1);
	
	int length2;
	GetNativeStringLength(2, length2);
	
	char[] sDescription = new char[length2 + 1];
	GetNativeString(2, sDescription, length2 + 1);
	
	int length3;
	GetNativeStringLength(3, length3);
	
	char[] sVersion_ConVar = new char[length3 + 1];
	GetNativeString(3, sVersion_ConVar, length3 + 1);
	
	int length4;
	GetNativeStringLength(4, length4);
	
	char[] sVersion = new char[length4 + 1];
	GetNativeString(4, sVersion, length4 + 1);
	
	if (ServerID <= 0)
	{
		Store_LogError("Error registering module '%s - %s' due to ServerID being 0 or below, please fix this issue.", sName, sVersion);
		return;
	}
		
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_RegisterPluginModule, sName, sDescription, sVersion_ConVar, sVersion, ServerID);
	Store_Local_TQuery("RegisterPluginModule", SQLCall_RegisterPluginModule, sQuery);
}

//Query - callback on plugin registration.
public void SQLCall_RegisterPluginModule(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		Store_LogError("SQL Error on SQLCall_RegisterPluginModule: %s", error);
	}
}

//Native - Pushes the base URL set to other plugins for them to use. ( Example: "http://www.domain.com/store/" )
public int Native_GetStoreBaseURL(Handle plugin, numParams)
{
	SetNativeString(1, g_baseURL, GetNativeCell(2));
}

//Native - Registers a client with a name specified.
public Native_Register(Handle plugin, numParams)
{
	char name[MAX_NAME_LENGTH];
	GetNativeString(2, name, sizeof(name));

	Register(GetNativeCell(1), name, GetNativeCell(3));
}

//Native - Registers a client and handles the name.
public int Native_RegisterClient(Handle plugin, numParams)
{
	RegisterClient(GetNativeCell(1), GetNativeCell(2));
}

//Native - Gets a clients account ID. (Not needed but used for backwards compatibility purposes)
public int Native_GetClientAccountID(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	int AccountID = GetSteamAccountID(client);
	
	if (AccountID == 0)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error retrieving client Steam Account ID %L.", client);
	}
	
	return AccountID;
}

//Native - Gets a clients UserID from database.
public int Native_GetClientUserID(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GetClientUserID, GetSteamAccountID(client));
	Handle hQuery = SQL_Query(g_hSQL, sQuery);
	
	int user_id = -1;
	
	if (hQuery == null)
	{
		char sError[512];
		SQL_GetError(g_hSQL, sError, sizeof(sError));
		Store_LogError("SQL Error on Native_GetClientUserID: %s", sError);
		return user_id;
	}
		
	if (SQL_FetchRow(hQuery))
	{
		user_id = SQL_FetchInt(hQuery, 0);
	}
	
	CloseHandle(hQuery);
	
	return user_id;
}

//Native - Gets categories for other plugins to use.
public int Native_GetCategories(Handle plugin, numParams)
{
	any data = 0;

	if (numParams == 4)
	{
		data = GetNativeCell(4);
	}
	
	int length;
	GetNativeStringLength(3, length);
	
	char[] sString = new char[length + 1];
	GetNativeString(3, sString, length + 1);
	
	GetCategories(-1, view_as<Store_GetItemsCallback>GetNativeFunction(1), plugin, GetNativeCell(2), sString, data);
}

//Native - Gets a categories display name.
public int Native_GetCategoryDisplayName(Handle plugin, numParams)
{
	SetNativeString(2, g_categories[GetCategoryIndex(GetNativeCell(1))][CategoryDisplayName], GetNativeCell(3));
}

//Native - Gets a categories description.
public int Native_GetCategoryDescription(Handle plugin, numParams)
{
	SetNativeString(2, g_categories[GetCategoryIndex(GetNativeCell(1))][CategoryDescription], GetNativeCell(3));
}

//Native - Gets a categories required plugin.
public int Native_GetCategoryPluginRequired(Handle plugin, numParams)
{
	SetNativeString(2, g_categories[GetCategoryIndex(GetNativeCell(1))][CategoryRequirePlugin], GetNativeCell(3));
}

//Native - Gets a categories server restriction.
public int Native_GetCategoryServerRestriction(Handle plugin, numParams)
{
	return g_categories[GetCategoryIndex(GetNativeCell(1))][CategoryDisableServerRestriction];
}

//Native - Gets a categories priority.
public int Native_GetCategoryPriority(Handle plugin, numParams)
{
	return g_categories[GetCategoryIndex(GetNativeCell(1))][CategoryPriority];
}

//Native - Gets items for other plugins to use.
public int Native_GetItems(Handle plugin, numParams)
{
	any data = 0;

	if (numParams == 5)
	{
		data = GetNativeCell(5);
	}
	
	int length;
	GetNativeStringLength(4, length);
	
	char[] sString = new char[length + 1];
	GetNativeString(4, sString, length + 1);
	
	GetItems(-1, GetNativeCell(1), view_as<Store_GetItemsCallback>GetNativeFunction(2), plugin, GetNativeCell(3), sString, data);
}

//Native - Gets an items name.
public int Native_GetItemName(Handle plugin, numParams)
{
	SetNativeString(2, g_items[GetItemIndex(GetNativeCell(1))][ItemName], GetNativeCell(3));
}

//Native - Gets an items display name.
public int Native_GetItemDisplayName(Handle plugin, numParams)
{
	SetNativeString(2, g_items[GetItemIndex(GetNativeCell(1))][ItemDisplayName], GetNativeCell(3));
}

//Native - Gets an items description.
public int Native_GetItemDescription(Handle plugin, numParams)
{
	SetNativeString(2, g_items[GetItemIndex(GetNativeCell(1))][ItemDescription], GetNativeCell(3));
}

//Native - Gets an items type.
public int Native_GetItemType(Handle plugin, numParams)
{
	SetNativeString(2, g_items[GetItemIndex(GetNativeCell(1))][ItemType], GetNativeCell(3));
}

//Native - Gets an items loadout slot.
public int Native_GetItemLoadoutSlot(Handle plugin, numParams)
{
	SetNativeString(2, g_items[GetItemIndex(GetNativeCell(1))][ItemLoadoutSlot], GetNativeCell(3));
}

//Native - Gets an items price.
public int Native_GetItemPrice(Handle plugin, numParams)
{
	return g_items[GetItemIndex(GetNativeCell(1))][ItemPrice];
}

//Native - Gets an items category.
public int Native_GetItemCategory(Handle plugin, numParams)
{
	return g_items[GetItemIndex(GetNativeCell(1))][ItemCategoryId];
}

//Native - Gets an items priority.
public int Native_GetItemPriority(Handle plugin, numParams)
{
	return g_items[GetItemIndex(GetNativeCell(1))][ItemPriority];
}

//Native - Gets an items server restrictions.
public int Native_GetItemServerRestriction(Handle plugin, numParams)
{
	return g_items[GetItemIndex(GetNativeCell(1))][ItemDisableServerRestriction];
}

//Native - Is an item buyable.
public int Native_IsItemBuyable(Handle plugin, numParams)
{
	return g_items[GetItemIndex(GetNativeCell(1))][ItemIsBuyable];
}

//Native - Is an item Tradeable.
public int Native_IsItemTradeable(Handle plugin, numParams)
{
	return g_items[GetItemIndex(GetNativeCell(1))][ItemIsTradeable];
}

//Native - Is an item Refundable.
public int Native_IsItemRefundable(Handle plugin, numParams)
{
	return g_items[GetItemIndex(GetNativeCell(1))][ItemIsRefundable];
}

//Native - Gets an items attributes.
public int Native_GetItemAttributes(Handle plugin, numParams)
{
	any data = 0;

	if (numParams == 3)
	{
		data = GetNativeCell(3);
	}
	
	char itemName[STORE_MAX_NAME_LENGTH];
	GetNativeString(1, itemName, sizeof(itemName));

	GetItemAttributes(itemName, view_as<Store_ItemGetAttributesCallback>GetNativeFunction(2), plugin, data);
}

//Native - Writes an items attributes.
public int Native_WriteItemAttributes(Handle plugin, numParams)
{
	any data = 0;

	if (numParams == 4)
	{
		data = GetNativeCell(4);
	}
	
	char itemName[STORE_MAX_NAME_LENGTH];
	GetNativeString(1, itemName, sizeof(itemName));

	int attrsLength = 10 * 1024;
	GetNativeStringLength(2, attrsLength);
	
	char[] attrs = new char[attrsLength];
	GetNativeString(2, attrs, attrsLength);

	WriteItemAttributes(itemName, attrs, view_as<Store_BuyItemCallback>GetNativeFunction(3), plugin, data);
}

//Native - Gets loadouts for other plugins to use.
public int Native_GetLoadouts(Handle plugin, numParams)
{
	any data = 0;
	
	if (numParams == 4)
	{
		data = GetNativeCell(4);
	}
	
	GetLoadouts(GetNativeCell(1), view_as<Store_GetItemsCallback>GetNativeFunction(2), plugin, GetNativeCell(3), data);
}

//Native - Gets a loadouts display name.
public int Native_GetLoadoutDisplayName(Handle plugin, numParams)
{
	SetNativeString(2, g_loadouts[GetLoadoutIndex(GetNativeCell(1))][LoadoutDisplayName], GetNativeCell(3));
}

//Native - Gets a loadouts required game.
public int Native_GetLoadoutGame(Handle plugin, numParams)
{
	SetNativeString(2, g_loadouts[GetLoadoutIndex(GetNativeCell(1))][LoadoutGame], GetNativeCell(3));
}

//Native - Gets a loadouts required class.
public int Native_GetLoadoutClass(Handle plugin, numParams)
{
	SetNativeString(2, g_loadouts[GetLoadoutIndex(GetNativeCell(1))][LoadoutClass], GetNativeCell(3));
}

//Native - Gets a loadouts required team.
public int Native_GetLoadoutTeam(Handle plugin, numParams)
{
	return g_loadouts[GetLoadoutIndex(GetNativeCell(1))][LoadoutTeam];
}

//Native - Gets a clients loadouts.
public int Native_GetClientLoadouts(Handle plugin, numParams)
{
	any data = 0;
	
	if (numParams == 5)
	{
		data = GetNativeCell(3);
	}
	
	GetClientLoadouts(GetNativeCell(1), view_as<Store_GetUserLoadoutsCallback>GetNativeFunction(2), plugin, data);
}

//Native - Gets a users items for other plugins to use.
public int Native_GetUserItems(Handle plugin, numParams)
{
	any data = 0;
	
	if (numParams == 5)
	{
		data = GetNativeCell(5);
	}
	
	GetUserItems(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), view_as<Store_GetUserItemsCallback>GetNativeFunction(4), plugin, data);
}

//Native - Gets a users items count for other plugins to use.
public Native_GetUserItemsCount(Handle plugin, numParams)
{
	any data = 0;
	
	if (numParams == 4)
	{
		data = GetNativeCell(4);
	}
	
	char itemName[STORE_MAX_NAME_LENGTH];
	GetNativeString(2, itemName, sizeof(itemName));

	GetUserItemsCount(GetNativeCell(1), itemName, view_as<Store_GetUserItemsCountCallback>GetNativeFunction(3), plugin, data);
}

//Native - Gets a clients credits.
public Native_GetCredits(Handle plugin, numParams)
{
	any data = 0;
	
	if (numParams == 3)
	{
		data = GetNativeCell(3);
	}
	
	GetCredits(GetNativeCell(1), view_as<Store_GetCreditsCallback>GetNativeFunction(2), plugin, data);
}

//Native - Gets a clients credits live.
public int Native_GetCreditsEx(Handle plugin, params)
{	
	char sQuery[MAX_QUERY_SIZES];
	Format(sQuery, sizeof(sQuery), sQuery_GetCreditsEx, GetNativeCell(1));
	Handle hQuery = SQL_Query(g_hSQL, sQuery);
	
	int credits = -1;
	
	if (hQuery == null)
	{
		char sError[512];
		SQL_GetError(g_hSQL, sError, sizeof(sError));
		Store_LogError("SQL Error on GetCreditsEx: %s", sError);
		return credits;
	}
		
	if (SQL_FetchRow(hQuery))
	{
		credits = SQL_FetchInt(hQuery, 0);
	}
	
	CloseHandle(hQuery);
	
	return credits;
}

//Native - Buys an item for a client.
public int Native_BuyItem(Handle plugin, numParams)
{
	any data = 0;

	if (numParams == 4)
	{
		data = GetNativeCell(4);
	}
	
	BuyItem(GetNativeCell(1), GetNativeCell(2), view_as<Store_BuyItemCallback>GetNativeFunction(3), plugin, data);
}

//Native - Removes an item from a client.
public int Native_RemoveUserItem(Handle plugin, numParams)
{
	any data = 0;

	if (numParams == 4)
	{
		data = GetNativeCell(4);
	}
	
	RemoveUserItem(GetNativeCell(1), GetNativeCell(2), view_as<Store_UseItemCallback>GetNativeFunction(3), plugin, data);
}

//Native - Sets an items equipped state on a client.
public int Native_SetItemEquippedState(Handle plugin, numParams)
{
	any data = 0;

	if (numParams == 6)
	{
		data = GetNativeCell(6);
	}
	
	SetItemEquippedState(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), view_as<Store_EquipItemCallback>GetNativeFunction(5), plugin, data);
}

//Native - Gets an items equipped state on a client.
public int Native_GetEquippedItemsByType(Handle plugin, numParams)
{
	char type[32];
	GetNativeString(2, type, sizeof(type));

	any data = 0;

	if (numParams == 5)
	{
		data = GetNativeCell(5);
	}
	
	GetEquippedItemsByType(GetNativeCell(1), type, GetNativeCell(3), view_as<Store_GetItemsCallback>GetNativeFunction(4), plugin, data);
}

//Native - Gives credits to a client.
public int Native_GiveCredits(Handle plugin, numParams)
{
	any data = 0;

	if (numParams == 4)
	{
		data = GetNativeCell(4);
	}

	GiveCredits(GetNativeCell(1), GetNativeCell(2), view_as<Store_GiveCreditsCallback>GetNativeFunction(3), plugin, data);
}

//Native - Give credits to multiple clients.
public int Native_GiveCreditsToUsers(Handle plugin, numParams)
{
	int length = GetNativeCell(2);
	
	int[] accountIds = new int[length];
	GetNativeArray(1, accountIds, length);

	GiveCreditsToUsers(accountIds, length, GetNativeCell(3));
}

//Native - Give a client an item.
public int Native_GiveItem(Handle plugin, numParams)
{
	any data = 0;
	
	if (numParams == 5)
	{
		data = GetNativeCell(5);
	}
	
	GiveItem(GetNativeCell(1), GetNativeCell(2), view_as<Store_AcquireMethod>GetNativeCell(3), view_as<Store_AccountCallback>GetNativeFunction(4), plugin, data);
}

//Native - Give different credits to clients.
public Native_GiveDifferentCreditsToUsers(Handle:plugin, params)
{
	new length = GetNativeCell(2);

	new accountIds[length];
	GetNativeArray(1, accountIds, length);

	new credits[length];
	GetNativeArray(3, credits, length);

	GiveDifferentCreditsToUsers(accountIds, length, credits);
}

//Native - Remove credits from a client.
public int Native_RemoveCredits(Handle plugin, numParams)
{
	any data = 0;

	if (numParams == 4)
	{
		data = GetNativeCell(4);
	}

	RemoveCredits(GetNativeCell(1), GetNativeCell(2), view_as<Store_RemoveCreditsCallback>GetNativeFunction(3), plugin, data);
}

//Native - Remove credits from multiple clients.
public int Native_RemoveCreditsFromUsers(Handle plugin, numParams)
{
	int length = GetNativeCell(2);

	int[] accountIds = new int[length];
	GetNativeArray(1, accountIds, length);

	RemoveCreditsFromUsers(accountIds, length, GetNativeCell(3));
}

//Natives - Remove different credits from clients.
public int Native_RemoveDifferentCreditsFromUsers(Handle plugin, numParams)
{
	int length = GetNativeCell(2);

	int[] accountIds = new int[length];
	GetNativeArray(1, accountIds, length);

	int[] credits = new int[length];
	GetNativeArray(3, credits, length);

	RemoveDifferentCreditsFromUsers(accountIds, length, credits);
}

//Native - Allows modules to query the store database.
public int Native_SQLTQuery(Handle plugin, numParams)
{
	SQLTCallback callback = view_as<SQLTCallback>GetNativeFunction(1);
	
	int size;
	GetNativeStringLength(2, size);
	
	char[] sQuery = new char[size];
	GetNativeString(2, sQuery, size);
	
	int data = GetNativeCell(3);
	DBPriority prio = view_as<DBPriority>GetNativeCell(4);
	
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, _:plugin);
	WritePackFunction(hPack, callback);
	WritePackCell(hPack, data);
	
	Store_Local_TQuery("Native", callback, sQuery, data, prio);
}

//Query - callback for native queries made by modules.
public void Query_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);
	
	Handle plugin = view_as<Handle>ReadPackCell(data);
	SQLTCallback callback = view_as<SQLTCallback>ReadPackFunction(data);
	int hPack = ReadPackCell(data);
	
	CloseHandle(data);
	
	Call_StartFunction(plugin, callback);
	Call_PushCell(owner);
	Call_PushCell(hndl);
	Call_PushString(error);
	Call_PushCell(hPack);
	Call_Finish();
}

//Native - Escapes a string with the SQL database.
public int Native_SQLEscapeString(Handle plugin, numParams)
{
	int size;
	GetNativeStringLength(1, size);
	
	char[] sOrig = new char[size];
	GetNativeString(1, sOrig, sizeof(size));
	
	size = 2 * size + 1;
	char[] sNew = new char[size];
	SQL_EscapeString(g_hSQL, sOrig, sNew, size);
	
	SetNativeString(2, sNew, size);
}

//Native - Processes a category to make sure it should be shown with the ServerID set.
public int Native_ProcessCategory(Handle plugin, numParams)
{
	int ServerID = GetNativeCell(1);
	int CategoryID = GetNativeCell(2);
	
	if (ServerID <= 0)
	{
		return true;
	}
	
	for (int i = 0; i < GetArraySize(hCategoriesCache); i++)
	{
		if (GetArrayCell(hCategoriesCache, i) == CategoryID)
		{
			if (GetArrayCell(hCategoriesCache2, i) == ServerID)
			{
				return true;
			}
		}
	}
	
	return false;
}

//Native - Processes an item to make sure it should be shown with the ServerID set.
public int Native_ProcessItem(Handle plugin, numParams)
{
	int ServerID = GetNativeCell(1);
	int ItemID = GetNativeCell(2);
	
	if (ServerID <= 0)
	{
		return true;
	}
	
	for (int i = 0; i < GetArraySize(hItemsCache); i++)
	{
		if (GetArrayCell(hItemsCache, i) == ItemID)
		{
			if (GetArrayCell(hItemsCache2, i) == ServerID)
			{
				return true;
			}
		}
	}
	
	return false;
}