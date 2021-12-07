#include <sourcemod>
#include <tf2_stocks>
#include <tf2>

public Plugin:myinfo =
{
	name = "Item's text remover",
	author = "CloveR special thanks to toazron1 @ Allied Modders forums",
	description = "Removes the found and trade text",
	version = "1.0.0.0",
	url = "http://forums.alliedmods.net/showthread.php?t=146270"
}

public OnPluginStart()
{
	HookEvent("item_found", Event_ItemFound, EventHookMode_Pre)
}

public Action:Event_ItemFound(Handle:event, const String:item[], bool:dontBroadcast)
{
        return Plugin_Handled
}