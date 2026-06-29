#define PLUGIN_VERSION "1.3.0"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

/**
 * 1.3:
 * > Fixed plugin spamming error log with invalid entity messages
 * 
 * 1.2:
 * > Moved check from player_spawn to post_inventory_application to catch cabinets
 * 
 * 1.1:
 * > Fixed plugin not removing halos from players immediately
 */

public Plugin:myinfo = 
{
	name = "Halo Remover",
	author = "Davejk",
	description = "Removes halos from players who have them equipped.",
	version = PLUGIN_VERSION,
	url = "http://davejk.net/"
}

public OnPluginStart()
{
	CreateConVar("tf_haloremover_version", PLUGIN_VERSION, "Halo Remover plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("post_inventory_application", CallCheckInventory, EventHookMode_Post);
}
public Action:CallCheckInventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, CheckInventory);
}
public Action:CheckInventory(Handle:timer)
{
	new edict;
	while((edict = FindEntityByClassname(edict, "tf_wearable_item")) != -1)
	{
		if(GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex") == 125) {
			RemoveEdict(edict);
			edict++;
		}
	}
}