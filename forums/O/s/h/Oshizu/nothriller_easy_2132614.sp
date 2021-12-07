#include <tf2attributes>

public OnPluginStart()
{
	HookEvent("post_inventory_application", InventoryUpdate, EventHookMode_Post)
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post)
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	TF2Attrib_SetByName(client, "special taunt", 1.0);
} 

public Action:InventoryUpdate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new hClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	TF2Attrib_SetByName(hClientWeapon, "special taunt", 1.0);
} 

