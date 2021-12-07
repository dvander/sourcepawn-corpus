#pragma semicolon 1

#include <sourcemod>
#include <store/store-core>
#include <store/store-backend>
#include <store/store-logging>
#include <store/store-inventory>
#include <colors>

new String:g_currencyName[64];

new bool:g_hideEmptyCategories = false;

new bool:g_confirmItemPurchase = false;

new bool:g_allowBuyingDuplicates = false;

new bool:g_hideCategoryDescriptions = false;

new Handle:g_buyItemForward;
new Handle:g_buyItemPostForward;

/**
 * Called before plugin is loaded.
 * 
 * @param myself    The plugin handle.
 * @param late      True if the plugin was loaded after map change, false on map start.
 * @param error     Error message if load failed.
 * @param err_max   Max length of the error message.
 *
 * @return          APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("Store_OpenShop", Native_OpenShop);
	CreateNative("Store_OpenShopCategory", Native_OpenShopCategory);
	
	RegPluginLibrary("store-shop");	
	return APLRes_Success;
}

public Plugin:myinfo =
{
	name        = "[Store] Shop",
	author      = "alongub",
	description = "Shop component for [Store]",
	version     = STORE_VERSION,
	url         = "https://github.com/alongubkin/store"
};

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
	LoadConfig();

	g_buyItemForward = CreateGlobalForward("Store_OnBuyItem", ET_Event, Param_Cell, Param_Cell);
	g_buyItemPostForward = CreateGlobalForward("Store_OnBuyItem_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	LoadTranslations("common.phrases");
	LoadTranslations("store.phrases");

	Store_AddMainMenuItem("Shop", "Shop Description", _, OnMainMenuShopClick, 2);
}

/**
 * Configs just finished getting executed.
 */
public OnConfigsExecuted()
{    
	Store_GetCurrencyName(g_currencyName, sizeof(g_currencyName));
}

/**
 * Load plugin config.
 */
LoadConfig() 
{
	new Handle:kv = CreateKeyValues("root");
	
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/store/shop.cfg");
	
	if (!FileToKeyValues(kv, path)) 
	{
		CloseHandle(kv);
		SetFailState("Can't read config file %s", path);
	}

	decl String:menuCommands[255];
	KvGetString(kv, "shop_commands", menuCommands, sizeof(menuCommands), "!shop /shop");
	Store_RegisterChatCommands(menuCommands, ChatCommand_OpenShop);
	
	g_confirmItemPurchase = bool:KvGetNum(kv, "confirm_item_purchase", 0);

	g_hideEmptyCategories = bool:KvGetNum(kv, "hide_empty_categories", 0);

	g_hideCategoryDescriptions = bool:KvGetNum(kv, "hide_category_descriptions", 0);

	g_allowBuyingDuplicates = bool:KvGetNum(kv, "allow_buying_duplicates", 0);

	CloseHandle(kv);
}

public OnMainMenuShopClick(client, const String:value[])
{
	OpenShop(client);
}

public ChatCommand_OpenShop(client)
{
	OpenShop(client);
}

/**
 * Opens the shop menu for a client.
 *
 * @param client			Client index.
 *
 * @noreturn
 */
OpenShop(client)
{
	Store_GetCategories(GetCategoriesCallback, true, GetClientSerial(client));
}

new Handle:categories_menu[MAXPLAYERS+1];

public GetCategoriesCallback(ids[], count, any:serial)
{		
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
		return;
	
	categories_menu[client] = CreateMenu(ShopMenuSelectHandle);
	SetMenuTitle(categories_menu[client], "%T\n \n", "Shop", client);
	
	for (new category = 0; category < count; category++)
	{
		decl String:requiredPlugin[STORE_MAX_REQUIREPLUGIN_LENGTH];
		Store_GetCategoryPluginRequired(ids[category], requiredPlugin, sizeof(requiredPlugin));
		
		if (!StrEqual(requiredPlugin, "") && !Store_IsItemTypeRegistered(requiredPlugin))
			continue;

		new Handle:pack = CreateDataPack();
		WritePackCell(pack, GetClientSerial(client));
		WritePackCell(pack, ids[category]);
		WritePackCell(pack, count - category - 1);
		
		new Handle:filter = CreateTrie();
		SetTrieValue(filter, "is_buyable", 1);
		SetTrieValue(filter, "category_id", ids[category]);
		SetTrieValue(filter, "flags", GetUserFlagBits(client));

		Store_GetItems(filter, GetItemsForCategoryCallback, true, pack);
	}
}

public GetItemsForCategoryCallback(ids[], count, any:pack)
{
	ResetPack(pack);
	
	new serial = ReadPackCell(pack);
	new categoryId = ReadPackCell(pack);
	new left = ReadPackCell(pack);
	
	CloseHandle(pack);
	
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
		return;


	// Display this category if "hide_empty_categories"
	// is disabled or if it has items.
	if (!g_hideEmptyCategories || count > 0)
	{
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetCategoryDisplayName(categoryId, displayName, sizeof(displayName));

		if (!g_hideCategoryDescriptions)
		{
			decl String:description[STORE_MAX_DESCRIPTION_LENGTH];
			Store_GetCategoryDescription(categoryId, description, sizeof(description));

			decl String:itemText[sizeof(displayName) + 1 + sizeof(description)];
			Format(itemText, sizeof(itemText), "%s\n%s", displayName, description);
		}
		
		decl String:itemValue[8];
		IntToString(categoryId, itemValue, sizeof(itemValue));
		
		AddMenuItem(categories_menu[client], itemValue, displayName);
	}

	if (left == 0)
	{
		SetMenuExitBackButton(categories_menu[client], true);
		DisplayMenu(categories_menu[client], client, 0);
	}
}

public ShopMenuSelectHandle(Handle:menu, MenuAction:action, client, slot)
{
	if (action == MenuAction_Select)
	{
		new String:categoryIndex[64];
		
		if (GetMenuItem(menu, slot, categoryIndex, sizeof(categoryIndex)))
			OpenShopCategory(client, StringToInt(categoryIndex));
	}
	else if (action == MenuAction_Cancel)
	{
		if (slot == MenuCancel_ExitBack)
		{
			Store_OpenMainMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/**
 * Opens the shop menu for a client in a specific category.
 *
 * @param client			Client index.
 * @param categoryId		The category that you want to open.
 *
 * @noreturn
 */
OpenShopCategory(client, categoryId)
{
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, GetClientSerial(client));
	WritePackCell(pack, categoryId);
	
	new Handle:filter = CreateTrie();
	SetTrieValue(filter, "is_buyable", 1);
	SetTrieValue(filter, "category_id", categoryId);
	SetTrieValue(filter, "flags", GetUserFlagBits(client));

	Store_GetItems(filter, GetItemsCallback, true, pack);
}

public GetItemsCallback(ids[], count, any:pack)
{	
	ResetPack(pack);
	
	new serial = ReadPackCell(pack);
	new categoryId = ReadPackCell(pack);
	
	CloseHandle(pack);
	
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
		return;
	
	if (count == 0)
	{
		PrintToChat(client, "%s%t", STORE_PREFIX, "No items in this category");
		OpenShop(client);
		
		return;
	}
	
	decl String:categoryDisplayName[64];
	Store_GetCategoryDisplayName(categoryId, categoryDisplayName, sizeof(categoryDisplayName));
		
	new Handle:menu = CreateMenu(ShopCategoryMenuSelectHandle);
	SetMenuTitle(menu, "%T - %s\n \n", "Shop", client, categoryDisplayName);

	for (new item = 0; item < count; item++)
	{		
		decl String:displayName[64];
		decl String:description[128];
		decl String:text[sizeof(displayName) + sizeof(description) + 5];		

		Store_GetItemDisplayName(ids[item], displayName, sizeof(displayName));

		if(g_hideCategoryDescriptions==false){
			Store_GetItemDescription(ids[item], description, sizeof(description));
			Format(text, sizeof(text), "%s [%s%d]\n%s", displayName,  g_currencyName, Store_GetItemPrice(ids[item]), description);
		} else {
			Format(text, sizeof(text), "%s [%s%d]", displayName, g_currencyName, Store_GetItemPrice(ids[item]));
		}
		
		decl String:value[8];
		IntToString(ids[item], value, sizeof(value));
		
		AddMenuItem(menu, value, text);    
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);   
}

public ShopCategoryMenuSelectHandle(Handle:menu, MenuAction:action, client, slot)
{
	if (action == MenuAction_Select)
	{
		new String:value[12];

		if (GetMenuItem(menu, slot, value, sizeof(value)))
		{
			DoBuyItem(client, StringToInt(value));
		}
	}
	else if (action == MenuAction_Cancel)
	{
		OpenShop(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

DoBuyItem(client, itemId, bool:confirmed=false, bool:checkeddupes=false)
{
	if (g_confirmItemPurchase && !confirmed)
	{
		DisplayConfirmationMenu(client, itemId);
	}
	else if (!g_allowBuyingDuplicates && !checkeddupes)
	{
		decl String:itemName[STORE_MAX_NAME_LENGTH];
		Store_GetItemName(itemId, itemName, sizeof(itemName));

		new Handle:pack = CreateDataPack();
		WritePackCell(pack, GetClientSerial(client));
		WritePackCell(pack, itemId);

		Store_GetUserItemCount(GetSteamAccountID(client), itemName, DoBuyItem_ItemCountCallBack, pack);
	}
	else
	{
		new Action:result = Plugin_Continue;

		Call_StartForward(g_buyItemForward);
		Call_PushCell(client);
		Call_PushCell(itemId);
		Call_Finish(_:result);

		if (result == Plugin_Handled || result == Plugin_Stop)
		{
			// handled or stopped
			return;
		}

		new Handle:pack = CreateDataPack();
		WritePackCell(pack, GetClientSerial(client));
		WritePackCell(pack, itemId);

		Store_BuyItem(GetSteamAccountID(client), itemId, OnBuyItemComplete, pack);
	}
}

public DoBuyItem_ItemCountCallBack(count, any:pack)
{
	ResetPack(pack);

	new client = GetClientFromSerial(ReadPackCell(pack));
	if (client == 0)
	{
		CloseHandle(pack);
		return;
	}

	new itemId = ReadPackCell(pack);

	CloseHandle(pack);

	if (count <= 0)
	{
		DoBuyItem(client, itemId, true, true);
	}
	else
	{
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		PrintToChat(client, "%s%t", STORE_PREFIX, "Already purchased item", displayName);
	}
}

DisplayConfirmationMenu(client, itemId)
{
	decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
	Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));

	new Handle:menu = CreateMenu(ConfirmationMenuSelectHandle);
	SetMenuTitle(menu, "%T", "Item Purchase Confirmation", client,  displayName);

	decl String:value[8];
	IntToString(itemId, value, sizeof(value));

	AddMenuItem(menu, value, "Yes");
	AddMenuItem(menu, "no", "No");

	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);  
}

public ConfirmationMenuSelectHandle(Handle:menu, MenuAction:action, client, slot)
{
	if (action == MenuAction_Select)
	{
		new String:value[12];
		if (GetMenuItem(menu, slot, value, sizeof(value)))
		{
			if (StrEqual(value, "no"))
			{
				OpenShop(client);
			}
			else
			{
				DoBuyItem(client, StringToInt(value), true);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		OpenShop(client);
	}
	else if (action == MenuAction_DisplayItem) 
	{
		decl String:display[64];
		GetMenuItem(menu, slot, "", 0, _, display, sizeof(display));

		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%T", display, client);

		return RedrawMenuItem(buffer);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}

	return false;
}

public OnBuyItemComplete(bool:success, any:pack)
{
	ResetPack(pack);

	new client = GetClientFromSerial(ReadPackCell(pack));
	if (client == 0)
	{
		CloseHandle(pack);
		return;
	}

	new itemId = ReadPackCell(pack);

	CloseHandle(pack);

	if (success)
	{
		decl String:displayName[64];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));

		CPrintToChat(client, "%s%t", STORE_PREFIX, "Item Purchase Successful", displayName);
	}
	else
	{
		CPrintToChat(client, "%s%t", STORE_PREFIX, "Not enough credits to buy", g_currencyName);
	}
	
	OpenShop(client);

	Call_StartForward(g_buyItemPostForward);
	Call_PushCell(client);
	Call_PushCell(itemId);
	Call_PushCell(success);
	Call_Finish();
}

public Native_OpenShop(Handle:plugin, params)
{       
	OpenShop(GetNativeCell(1));
}

public Native_OpenShopCategory(Handle:plugin, params)
{       
	OpenShopCategory(GetNativeCell(1), GetNativeCell(2));
}