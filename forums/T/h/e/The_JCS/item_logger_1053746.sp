#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION  "1.0"

public Plugin:myinfo = 
{
	name = "Item Found Logger",
	author = "TheJCS",
	description = "Log all items found on the server",
	version = PLUGIN_VERSION,
	url = "http://www.thejcs.com.br"
};

public OnPluginStart()
{
	CreateConVar("sm_itemlogger", PLUGIN_VERSION, "Item Found Logger plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hFile = CreateConVar("sm_itemlogger_file", "items.txt", "File to log items found", FCVAR_PLUGIN);
	
	HookEvent("item_found", Event_ItemFound);
}

public Action:Event_ItemFound(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:fileName[64];
	GetConVarString(g_hFile, fileName, sizeof(fileName));
	
	decl String:date[64];
	FormatTime(date, sizeof(date), "%x %X", GetTime());
	
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	
	new String:steamid[64];
	GetClientAuthString(client, steamid, sizeof(steamid));
	
	new String:playerName[64];
	GetClientName(client, playerName, sizeof(playerName));

	new String:item[64];
	GetEventString(event, "item", item, sizeof(item));
	
	new Handle:hFile = OpenFile(fileName, "a");
	WriteFileLine(hFile, "%s: %s (%s) found %s", date, playerName, steamid, item);
	CloseHandle(hFile);
}

