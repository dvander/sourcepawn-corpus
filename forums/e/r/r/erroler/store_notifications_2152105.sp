#include <sourcemod>
#include <store>
#include <morecolors>

public Plugin:myinfo =
{
	name = "[Store] Item Buy Notification",
	author = "Erroler",
	description = "",
	version = "1.337",
	url = "www.ptfun.net"
};

public OnPluginStart() { LoadTranslations("store_notifications.phrases"); }

public Store_OnBuyItem_Post(client, itemId, bool:success)
{
	if (!success)
		return;
	//
	new String:steamid[45];
	GetClientAuthString(client, steamid, sizeof(steamid));
	//
	decl String:displayName[64];
	Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
	//
	new String:nameclient[45];
	GetClientName(client, nameclient, sizeof(nameclient));
	//
	new price = Store_GetItemPrice(itemId);
	//
	new String:Chat[128];
	FormatEx(Chat, sizeof(Chat), "%t", "Buy Notification Chat", nameclient, steamid, displayName, price);
	if (Chat[0] != '\0') CPrintToChatAllEx(client, "%s", Chat);
	Store_LogInfo("%t", "Buy Notification Log", nameclient, steamid, displayName, price);
}