#include <sdktools>

public Plugin:myinfo = 
{
	name = "Magical Mercenary Remover",
	author = "Jin",
	description = "Removes All Equipped Magical Mercenary",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	HookEvent("post_inventory_application", CallCheckInventory, EventHookMode_Post);
}

public Action:CallCheckInventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, CheckInventory);
}

public Action:CheckInventory(Handle:timer)
{
	new edict;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		if(GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex") == 30297) 
		{
			RemoveEdict(edict);
			edict++;
		}
	}
}