#pragma semicolon 1

#include <sourcemod>
#include <store>
#include <smjansson>

#define MAX_COMMANDITEMS 512

enum CommandItem
{
	String:CommandItemName[STORE_MAX_NAME_LENGTH],
	String:CommandItemText[255],
	CommandItemTeams[5]
}

new g_commandItems[MAX_COMMANDITEMS][CommandItem];
new g_commandItemCount;

new Handle:g_commandItemsNameIndex;

public Plugin:myinfo =
{
	name        = "[Store] CommandItems Hold",
	author      = "alongub edited by shanapu",
	description = "CommandItems component for [Store]",
	version     = "1.0.1a",
};

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
    LoadTranslations("store.phrases");
    Store_RegisterItemType("commanditemhold", OnCommandItemUse, OnCommandItemAttributesLoad);
}

/** 
 * Called when a new API library is loaded.
 */
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "store-inventory"))
	{
		Store_RegisterItemType("commanditemhold", OnCommandItemUse, OnCommandItemAttributesLoad);
	}	
}

public Store_OnReloadItems() 
{
	if (g_commandItemsNameIndex != INVALID_HANDLE)
		CloseHandle(g_commandItemsNameIndex);
		
	g_commandItemsNameIndex = CreateTrie();
	g_commandItemCount = 0;
}

public OnCommandItemAttributesLoad(const String:itemName[], const String:attrs[])
{
	strcopy(g_commandItems[g_commandItemCount][CommandItemName], STORE_MAX_NAME_LENGTH, itemName);
		
	SetTrieValue(g_commandItemsNameIndex, g_commandItems[g_commandItemCount][CommandItemName], g_commandItemCount);
	
	new Handle:json = json_load(attrs);
	json_object_get_string(json, "command", g_commandItems[g_commandItemCount][CommandItemText], 255);

	new Handle:teams = json_object_get(json, "teams");

	for (new i = 0, size = json_array_size(teams); i < size; i++)
		g_commandItems[g_commandItemCount][CommandItemTeams][i] = json_array_get_int(teams, i);

	CloseHandle(teams);
	CloseHandle(json);

	g_commandItemCount++;
}

public Store_ItemUseAction:OnCommandItemUse(client, itemId, bool:equipped)
{
	if (!IsClientInGame(client))
	{
		return Store_DoNothing;
	}

	decl String:itemName[STORE_MAX_NAME_LENGTH];
	Store_GetItemName(itemId, itemName, sizeof(itemName));

	new commandItemhold = -1;
	if (!GetTrieValue(g_commandItemsNameIndex, itemName, commandItemhold))
	{
		PrintToChat(client, "%s%t",  "No item attributes");
		return Store_DoNothing;
	}

	new clientTeam = GetClientTeam(client);

	new bool:teamAllowed = false;
	for (new teamIndex = 0; teamIndex < 5; teamIndex++)
	{
		if (g_commandItems[commandItemhold][CommandItemTeams][teamIndex] == clientTeam)
		{
			teamAllowed = true;
			break;
		}
	}

	if (!teamAllowed)
	{
		return Store_DoNothing;
	}

	decl String:clientName[64];
	GetClientName(client, clientName, sizeof(clientName));

	decl String:clientTeamStr[13];
	IntToString(clientTeam, clientTeamStr, sizeof(clientTeamStr));

	decl String:clientAuth[32];
	GetClientAuthString(client, clientAuth, sizeof(clientAuth));

	decl String:clientUser[11];
	Format(clientUser, sizeof(clientUser), "#%d", GetClientUserId(client));

	decl String:commandText[255];
	strcopy(commandText, sizeof(commandText), g_commandItems[commandItemhold][CommandItemText]);

	ReplaceString(commandText, sizeof(commandText), "{clientName}", clientName, false);
	ReplaceString(commandText, sizeof(commandText), "{clientTeam}", clientTeamStr, false);		
	ReplaceString(commandText, sizeof(commandText), "{clientAuth}", clientAuth, false);
	ReplaceString(commandText, sizeof(commandText), "{clientUser}", clientUser, false);		

	ServerCommand(commandText);
	return Store_DoNothing;
}