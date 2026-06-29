#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <store>
#include <smjansson>

enum WeaponColor
{
	String:ColorName[STORE_MAX_NAME_LENGTH],
	Color[4]
}

new weaponOffset;

new g_colors[512][WeaponColor];
new g_colorCount = 0;

new Handle:g_colorNameIndex = INVALID_HANDLE;

new String:g_game[32];

public Plugin:myinfo =
{
	name        = "[Store] Weapon Colors",
	author      = "Phault",
	description = "Weapon Colors component for [Store]",
	version     = "1.1-alpha",
	url         = "https://github.com/Phault/store-weaponcolors"
};

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("store.phrases");

	weaponOffset = FindSendPropInfo("CBasePlayer","m_hMyWeapons");

	GetGameFolderName(g_game, sizeof(g_game));

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("item_pickup", OnItemPickup);

	if (StrEqual(g_game, "tf"))
		HookEvent("post_inventory_application", OnPostInventoryApplication);

	Store_RegisterItemType("weaponcolors", OnEquip, LoadItem);
}

/** 
 * Called when a new API library is loaded.
 */
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "store-inventory"))
	{
		Store_RegisterItemType("weaponcolors", OnEquip, LoadItem);
	}	
}

public Store_OnReloadItems() 
{
	if (g_colorNameIndex != INVALID_HANDLE)
		CloseHandle(g_colorNameIndex);
		
	g_colorNameIndex = CreateTrie();
	g_colorCount = 0;
}

public LoadItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_colors[g_colorCount][ColorName], STORE_MAX_NAME_LENGTH, itemName);
		
	SetTrieValue(g_colorNameIndex, g_colors[g_colorCount][ColorName], g_colorCount);
	
	new Handle:json = json_load(attrs);

	if (json == INVALID_HANDLE)
	{
		LogError("%s Error loading item attributes : '%s'.", STORE_PREFIX, itemName);
		return;
	}

	new Handle:color = json_object_get(json, "color");

	if (color == INVALID_HANDLE)
	{
		g_colors[g_colorCount][Color] = { 255, 255, 255, 255 };
	}
	else
	{
		for (new i = 0; i < 4; i++)
			g_colors[g_colorCount][Color][i] = json_array_get_int(color, i);

		CloseHandle(color);
	}

	CloseHandle(json);
	g_colorCount++;
}

public Store_ItemUseAction:OnEquip(client, itemId, bool:equipped)
{
	if (!IsClientInGame(client))
	{
		return Store_DoNothing;
	}
	
	decl String:name[STORE_MAX_NAME_LENGTH];
	Store_GetItemName(itemId, name, sizeof(name));
	
	decl String:loadoutSlot[STORE_MAX_LOADOUTSLOT_LENGTH];
	Store_GetItemLoadoutSlot(itemId, loadoutSlot, sizeof(loadoutSlot));
	
	if (equipped)
	{
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Unequipped item", displayName);

		return Store_UnequipItem;
	}
	else
	{
		new weaponcolor = -1;
		if (!GetTrieValue(g_colorNameIndex, name, weaponcolor))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			return Store_DoNothing;
		}
			
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item", displayName);

		SetWeaponColors(client, name);

		return Store_EquipItem;
	}
}

public Action:OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (0<client<=GetMaxClients() && IsClientInGame(client))
		Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "weaponcolors", Store_GetClientLoadout(client), OnGetPlayerWeaponColor, client);
	return Plugin_Continue;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (0<client<=GetMaxClients() && IsClientInGame(client))
		Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "weaponcolors", Store_GetClientLoadout(client), OnGetPlayerWeaponColor, client);
	return Plugin_Continue;
}

public Action:OnPostInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (0<client<=GetMaxClients() && IsClientInGame(client))
		Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "weaponcolors", Store_GetClientLoadout(client), OnGetPlayerWeaponColor, client);
	return Plugin_Continue;
}

public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
	SetEntityRenderColor(weaponIndex, 255, 255, 255, 255);
	SetEntityRenderMode(weaponIndex, RenderMode:0);
}

public OnGetPlayerWeaponColor(ids[], count, any:client)
{
	if (client == 0 && IsPlayerAlive(client))
		return;

	for (new index = 0; index < count; index++)
	{
		decl String:itemName[32];
		Store_GetItemName(ids[index], itemName, sizeof(itemName));

		SetWeaponColors(client, itemName);
	}
}

SetWeaponColors(client, String:itemName[])
{
	new weaponcolor = -1;

	if (!GetTrieValue(g_colorNameIndex, itemName, weaponcolor))
	{
		PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
		return;
	}

	new color[4];
	Array_Copy(g_colors[weaponcolor][Color], color, sizeof(color));

	new ent = -1;
	for(new i = 0; i <= 47; i++) { 
        ent = GetEntDataEnt2(client,weaponOffset + (i * 4)); 

        if(ent != -1)
        { 
			SetEntityRenderColor(ent, color[0], color[1], color[2], color[3]);
			SetEntityRenderMode(ent, RenderMode:1);
        } 
	}
}

/**
 * Copies a 1 dimensional static array.
 *
 * @param array			Static Array to copy from.
 * @param newArray		New Array to copy to.
 * @param size			Size of the array (or number of cells to copy)
 * @noreturn
 */
stock Array_Copy(const any:array[], any:newArray[], size)
{
	for (new i=0; i < size; i++) 
	{
		newArray[i] = array[i];
	}
}