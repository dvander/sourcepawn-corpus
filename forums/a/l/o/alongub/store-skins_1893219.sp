#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <store>
#include <smjansson>
#include <smartdm>

enum Skin
{
	String:SkinName[STORE_MAX_NAME_LENGTH],
	String:SkinModelPath[PLATFORM_MAX_PATH], 
	SkinTeams[5]
}

new g_skins[1024][Skin];
new g_skinCount = 0;

new Handle:g_skinNameIndex;

new String:g_game[32];

public Plugin:myinfo =
{
    name        = "[Store] Skins",
    author      = "alongub",
    description = "Skins component for [Store]",
    version     = "1.0.8-alpha",
    url         = "https://github.com/alongubkin/store"
};

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	Store_RegisterItemType("skin", OnEquip, LoadItem);
	GetGameFolderName(g_game, sizeof(g_game));
}

/**
 * Map is starting
 */
public OnMapStart()
{
	for (new skin = 0; skin < g_skinCount; skin++)
	{
		if (strcmp(g_skins[skin][SkinModelPath], "") != 0 && (FileExists(g_skins[skin][SkinModelPath]) || FileExists(g_skins[skin][SkinModelPath], true)))
		{
			PrecacheModel(g_skins[skin][SkinModelPath]);
			Downloader_AddFileToDownloadsTable(g_skins[skin][SkinModelPath]);
		}
	}
}

/** 
 * Called when a new API library is loaded.
 */
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "store-inventory"))
	{
		Store_RegisterItemType("skin", OnEquip, LoadItem);
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(1.0, Timer_Spawn, GetClientSerial(client));
	
	return Plugin_Continue;
}

public Action:Timer_Spawn(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
		return Plugin_Continue;
		
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "skin", Store_GetClientLoadout(client), OnGetPlayerSkin, serial);
	
	return Plugin_Continue;
}

public Store_OnClientLoadoutChanged(client)
{
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "skin", Store_GetClientLoadout(client), OnGetPlayerSkin, GetClientSerial(client));
}

public OnGetPlayerSkin(ids[], count, any:serial)
{
	new client = GetClientFromSerial(serial);

	if (client == 0)
		return;
		
	if (!IsClientInGame(client))
		return;
	
	if (!IsPlayerAlive(client))
		return;
	
	new team = GetClientTeam(client);
	for (new index = 0; index < count; index++)
	{
		decl String:itemName[STORE_MAX_NAME_LENGTH];
		Store_GetItemName(ids[index], itemName, sizeof(itemName));
		
		new skin = -1;
		if (!GetTrieValue(g_skinNameIndex, itemName, skin))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			continue;
		}

		new bool:teamAllowed = false;
		for (new teamIndex = 0; teamIndex < 5; teamIndex++)
		{
			if (g_skins[skin][SkinTeams][teamIndex] == team)
			{
				teamAllowed = true;
				break;
			}
		}


		if (!teamAllowed)
		{
			continue;
		}

		if (StrEqual(g_game, "tf"))
		{
			SetVariantString(g_skins[skin][SkinModelPath]);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		}
		else
		{
			SetEntityModel(client, g_skins[skin][SkinModelPath]);
		}
	}
}

public Store_OnReloadItems() 
{
	if (g_skinNameIndex != INVALID_HANDLE)
		CloseHandle(g_skinNameIndex);
		
	g_skinNameIndex = CreateTrie();
	g_skinCount = 0;
}

public LoadItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_skins[g_skinCount][SkinName], STORE_MAX_NAME_LENGTH, itemName);

	SetTrieValue(g_skinNameIndex, g_skins[g_skinCount][SkinName], g_skinCount);

	new Handle:json = json_load(attrs);
	json_object_get_string(json, "model", g_skins[g_skinCount][SkinModelPath], PLATFORM_MAX_PATH);

	if (strcmp(g_skins[g_skinCount][SkinModelPath], "") != 0 && (FileExists(g_skins[g_skinCount][SkinModelPath]) || FileExists(g_skins[g_skinCount][SkinModelPath], true)))
	{
		PrecacheModel(g_skins[g_skinCount][SkinModelPath]);
		Downloader_AddFileToDownloadsTable(g_skins[g_skinCount][SkinModelPath]);
	}

	new Handle:teams = json_object_get(json, "teams");

	for (new i = 0, size = json_array_size(teams); i < size; i++)
		g_skins[g_skinCount][SkinTeams][i] = json_array_get_int(teams, i);

	CloseHandle(json);

	g_skinCount++;
}

public Store_ItemUseAction:OnEquip(client, itemId, bool:equipped)
{
	if (equipped)
		return Store_UnequipItem;
	
	PrintToChat(client, "%sYou've equipped a skin. It will take effect in the next round.", STORE_PREFIX);
	return Store_EquipItem;
}