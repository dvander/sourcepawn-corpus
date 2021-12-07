#include <friendly>
#include <tf2_stocks>

public OnPluginStart()
{
	HookEvent("post_inventory_application", Inventory_App);
}

public Inventory_App(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (TF2Friendly_IsFriendly(client))
	{
		TF2_RemoveAllWeapons(client);
	}
}