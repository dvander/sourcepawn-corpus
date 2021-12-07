#include <sourcemod>
#include <sdktools>
#include <gifts>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[ANY] Zephyrus Gift Grab - Test Plugin",
	author = "Zephyrus",
	description = "Gifts :333",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	Gifts_RegisterPlugin("Gifts_ClientPickUp");
}

public OnPluginEnd()
{
	Gifts_RemovePlugin();
}

public Gifts_ClientPickUp(client)
{
	PrintToChatAll("%N picked up the gift.", client);
}