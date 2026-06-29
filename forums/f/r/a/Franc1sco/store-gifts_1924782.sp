#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <gifts>
#include <store>

#define PLUGIN_VERSION	"1.0"

new String:g_currencyName[64];

public Plugin:myinfo =
{
	name = "[Store] Gifts",
	author = "Franc1sco steam: franug",
	description = "Gifts",
	version = PLUGIN_VERSION,
	url = "franug.com"
};

public OnPluginStart()
{
	Gifts_RegisterPlugin(Gifts_ClientPickUp);
}

public OnAllPluginsLoaded()
{
	Store_GetCurrencyName(g_currencyName, sizeof(g_currencyName));
}


public OnPluginEnd()
{
	Gifts_RemovePlugin();
}

public Gifts_ClientPickUp(client)
{
	new money = GetRandomInt(1,20);
	PrintToChat(client, "%s You received %i %s",STORE_PREFIX, money, g_currencyName);

	new account = Store_GetClientAccountID(client);
	Store_GiveCredits(account, money);
}

